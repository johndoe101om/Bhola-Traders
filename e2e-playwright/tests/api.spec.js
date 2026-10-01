const { test, expect } = require('@playwright/test');

const PIN = '9199';
const authHeaders = {
  'X-PIN': PIN,
  'Content-Type': 'application/json',
};

const uniqueSuffix = () => Math.random().toString(36).substring(2, 8);
const randomPhone = () => '9' + Math.floor(100000000 + Math.random() * 900000000).toString();

test.describe('AgriLedger Production API Integration & E2E Verification', () => {

  test('Health check endpoint returns status ok and correct metadata', async ({ request, baseURL }) => {
    const res = await request.get(`${baseURL}/health`);
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body.status).toBe('ok');
    expect(body.version).toBe('1.0.0');
    expect(body.timestamp).toBeDefined();
  });

  test('Enforces critical security headers on API responses', async ({ request, baseURL }) => {
    const res = await request.get(`${baseURL}/health`);
    const headers = res.headers();
    expect(headers['x-content-type-options']).toBe('nosniff');
    expect(headers['x-frame-options']).toBe('DENY');
    expect(headers['x-xss-protection']).toBe('1; mode=block');
    expect(headers['referrer-policy']).toBe('strict-origin-when-cross-origin');
  });

  test('Swagger OpenAPI schema is accessible and compliant', async ({ request, baseURL }) => {
    const res = await request.get(`${baseURL}/swagger/v1/swagger.json`);
    expect(res.status()).toBe(200);
    const doc = await res.json();
    expect(doc.openapi).toMatch(/^3\./);
    expect(doc.info.title).toBe('AgriLedger API');
  });

  test('Authentication enforcement: Rejects requests without PIN or with invalid PIN', async ({ request, baseURL }) => {
    // Missing PIN
    const noPinRes = await request.get(`${baseURL}/api/v1/parties`);
    expect(noPinRes.status()).toBe(401);
    const noPinBody = await noPinRes.json();
    expect(noPinBody.success).toBe(false);
    expect(noPinBody.message).toContain('PIN');

    // Invalid PIN
    const badPinRes = await request.get(`${baseURL}/api/v1/parties`, {
      headers: { 'X-PIN': '0000' }
    });
    expect(badPinRes.status()).toBe(401);
  });

  test('Parties CRUD: Validates input, creates party, and retrieves party ledger', async ({ request, baseURL }) => {
    // 1. Validation failure test (empty name, invalid party type)
    const invalidRes = await request.post(`${baseURL}/api/v1/parties`, {
      headers: authHeaders,
      data: {
        name: '',
        partyType: 'invalid_type'
      }
    });
    expect(invalidRes.status()).toBe(400);
    const invalidBody = await invalidRes.json();
    expect(invalidBody.success).toBe(false);
    expect(invalidBody.errors.length).toBeGreaterThan(0);

    // 2. Successful creation with unique attributes
    const partyName = `Kisan Ram Kumar ${uniqueSuffix()}`;
    const phone = randomPhone();
    const createRes = await request.post(`${baseURL}/api/v1/parties`, {
      headers: authHeaders,
      data: {
        name: partyName,
        partyType: 'farmer',
        phone: phone,
        village: 'Rampur'
      }
    });
    expect(createRes.status()).toBe(201);
    const createBody = await createRes.json();
    expect(createBody.success).toBe(true);
    expect(createBody.data.id).toBeDefined();
    expect(createBody.data.name).toBe(partyName);
    const partyId = createBody.data.id;

    // 3. Retrieve single party details
    const getRes = await request.get(`${baseURL}/api/v1/parties/${partyId}`, {
      headers: authHeaders
    });
    expect(getRes.status()).toBe(200);
    const getBody = await getRes.json();
    expect(getBody.data.id).toBe(partyId);
    expect(getBody.data.phone).toBe(phone);
  });

  test('Transactions Flow: Records grain purchase, computes totals, and updates balance', async ({ request, baseURL }) => {
    // 1. Create a party first (supplier/customer/farmer)
    const supplierName = `Supplier Shyam Lal ${uniqueSuffix()}`;
    const partyRes = await request.post(`${baseURL}/api/v1/parties`, {
      headers: authHeaders,
      data: {
        name: supplierName,
        partyType: 'supplier',
        phone: randomPhone(),
        village: 'Kalyanpur'
      }
    });
    expect(partyRes.status()).toBe(201);
    const party = (await partyRes.json()).data;

    // 2. Create purchase transaction
    const txnRes = await request.post(`${baseURL}/api/v1/transactions`, {
      headers: authHeaders,
      data: {
        partyId: party.id,
        direction: 'credit',
        txnType: 'purchase',
        commodity: 'wheat',
        quantityKg: 500,
        ratePerKg: 25,
        amount: 12500,
        paymentMode: 'cash',
        entryDate: new Date().toISOString().split('T')[0]
      }
    });
    expect(txnRes.status()).toBe(201);
    const txn = (await txnRes.json()).data;
    expect(txn.amount).toBe(12500);
    expect(txn.commodity).toBe('wheat');

    // 3. Verify transaction summary reflects new volume
    const summaryRes = await request.get(`${baseURL}/api/v1/transactions/summary`, {
      headers: authHeaders
    });
    expect(summaryRes.status()).toBe(200);
    const summaries = (await summaryRes.json()).data;
    expect(Array.isArray(summaries)).toBe(true);
    expect(summaries.length).toBeGreaterThan(0);
    expect(summaries[0].totalPurchaseAmount).toBeGreaterThanOrEqual(12500);
  });

  test('Bags Tracking Flow: Given and returned bag movements update outstanding balances', async ({ request, baseURL }) => {
    // 1. Create party
    const farmerName = `Farmer Hari Om ${uniqueSuffix()}`;
    const partyRes = await request.post(`${baseURL}/api/v1/parties`, {
      headers: authHeaders,
      data: {
        name: farmerName,
        partyType: 'farmer',
        village: 'Chandanpur'
      }
    });
    expect(partyRes.status()).toBe(201);
    const party = (await partyRes.json()).data;

    // 2. Issue 50 bags
    const issueRes = await request.post(`${baseURL}/api/v1/bags`, {
      headers: authHeaders,
      data: {
        partyId: party.id,
        movement: 'given',
        quantity: 50,
        entryDate: new Date().toISOString().split('T')[0]
      }
    });
    expect(issueRes.status()).toBe(201);

    // 3. Return 20 bags
    const returnRes = await request.post(`${baseURL}/api/v1/bags`, {
      headers: authHeaders,
      data: {
        partyId: party.id,
        movement: 'returned',
        quantity: 20,
        entryDate: new Date().toISOString().split('T')[0]
      }
    });
    expect(returnRes.status()).toBe(201);

    // 4. Check outstanding bags summary
    const summaryRes = await request.get(`${baseURL}/api/v1/bags/outstanding`, {
      headers: authHeaders
    });
    expect(summaryRes.status()).toBe(200);
    const summaryList = (await summaryRes.json()).data;
    expect(Array.isArray(summaryList)).toBe(true);
    const partySummary = summaryList.find(s => s.partyId === party.id);
    expect(partySummary).toBeDefined();
    expect(partySummary.bagsGiven).toBe(50);
    expect(partySummary.bagsReturned).toBe(20);
    expect(partySummary.bagsOutstanding).toBe(30);
  });

  test('Workforce Management: Employee creation, attendance marking, and wage payouts', async ({ request, baseURL }) => {
    // 1. Create employee
    const empName = `Ramesh Yadav ${uniqueSuffix()}`;
    const empRes = await request.post(`${baseURL}/api/v1/employees`, {
      headers: authHeaders,
      data: {
        name: empName,
        employeeType: 'labour',
        dailyWageRate: 450,
        phone: randomPhone()
      }
    });
    expect(empRes.status()).toBe(201);
    const employee = (await empRes.json()).data;
    expect(employee.dailyWageRate).toBe(450);

    // 2. Mark attendance (present)
    const today = new Date().toISOString().split('T')[0];
    const attRes = await request.post(`${baseURL}/api/v1/attendance`, {
      headers: authHeaders,
      data: {
        employeeId: employee.id,
        attendanceDate: today,
        status: 'present'
      }
    });
    expect([200, 201]).toContain(attRes.status());
    const attendance = (await attRes.json()).data;
    expect(attendance.status).toBe('present');

    // 3. Pay wage
    const payRes = await request.post(`${baseURL}/api/v1/employee-payments`, {
      headers: authHeaders,
      data: {
        employeeId: employee.id,
        paymentType: 'wage',
        amount: 450,
        paymentMode: 'cash',
        paymentDate: today
      }
    });
    expect([200, 201]).toContain(payRes.status());
    const payment = (await payRes.json()).data;
    expect(payment.amount).toBe(450);

    // 4. Verify employee details and list calculations
    const empDetailsRes = await request.get(`${baseURL}/api/v1/employees/${employee.id}`, {
      headers: authHeaders
    });
    expect(empDetailsRes.status()).toBe(200);
    const empDetails = (await empDetailsRes.json()).data;
    expect(empDetails.id).toBe(employee.id);
    expect(empDetails.name).toBe(empName);

    const empListRes = await request.get(`${baseURL}/api/v1/employees?q=${encodeURIComponent(empName)}`, {
      headers: authHeaders
    });
    expect(empListRes.status()).toBe(200);
    const empList = (await empListRes.json()).data;
    expect(empList.length).toBeGreaterThan(0);
    const foundEmp = empList.find(e => e.id === employee.id);
    expect(foundEmp).toBeDefined();
    expect(foundEmp.daysPresent).toBeGreaterThanOrEqual(1);
    expect(foundEmp.totalPaid).toBeGreaterThanOrEqual(450);
  });

});
