# Frontend-Backend API Mapping Analysis

## Backend Base URL
`https://expense-api-gateway-01kd.onrender.com`

---

## Personal Transactions

### 1. Create Personal Transaction
- **Frontend**: `POST /expenses/addpersonalTransaction`
- **Backend**: `POST /addpersonalTransaction` ✅ MATCH
- **Request Body**:
  ```javascript
  {
    transaction_type: "INCOME" | "EXPENSE" | "LOAN",
    amount: number,
    name: string,
    email: string | null,
    category: string | null,
    remark: string | null,
    payment_mode: "CASH" | "ONLINE" | "OTHER",
    loan_type: "BORROW" | "LENT" | null,
    transaction_date: "YYYY-MM-DD",  // ⚠️ FRONTEND SENDS ISO STRING
    transaction_time: "HH:mm",        // ⚠️ FRONTEND DOESN'T SEND THIS
    due_date: "YYYY-MM-DD" | null
  }
  ```
- **Backend Expects**: Separate `transaction_date` and `transaction_time` fields
- **Backend Response**:
  ```javascript
  {
    success: true,
    message: "Personal transaction created successfully",
    data: { /* transaction object */ }
  }
  ```

### 2. Get All Personal Transactions
- **Frontend**: `GET /expenses/allPersonalTransactions`
- **Backend**: `GET /allPersonalTransactions` ✅ MATCH
- **Query Params**: `page`, `limit`, `transaction_type`, `loan_type`, `payment_mode`, `category`, `name`, `search`, `start_date`, `end_date`
- **Backend Response**:
  ```javascript
  {
    success: true,
    transactions: [...],
    total: number,
    page: number,
    limit: number,
    totalPages: number,
    hasNextPage: boolean,
    hasPreviousPage: boolean
  }
  ```
- **Note**: Backend formats `transaction_date` as `YYYY-MM-DD` and `transaction_time` as `HH:mm`

### 3. Get Transaction By ID
- **Frontend**: `GET /expenses/transaction/:id`
- **Backend**: `GET /transaction/:id` ✅ MATCH
- **Backend Response**:
  ```javascript
  {
    success: true,
    message: "Transaction fetched successfully",
    data: { /* transaction with formatted date/time */ }
  }
  ```

### 4. Update Personal Transaction
- **Frontend**: `PUT /expenses/transaction/:id`
- **Backend**: `PUT /transaction/:id` ✅ MATCH
- **Request Body**: Same as create
- **⚠️ ISSUE**: Frontend sends combined datetime in `transaction_date`, backend expects separate fields

### 5. Delete Personal Transaction
- **Frontend**: `DELETE /expenses/transaction/:id`
- **Backend**: `DELETE /transaction/:id` ✅ MATCH
- **Backend**: Soft delete (sets `is_deleted: true`)

---

## Business Transactions

### 1. Create Business Transaction
- **Frontend**: `POST /expenses/addBusinessTransaction`
- **Backend**: `POST /addBusinessTransaction` ✅ MATCH
- **Request Body**:
  ```javascript
  {
    business_id: string,
    party_id: string | null,
    title: string,
    transaction_type: "SALE" | "PURCHASE" | "EXPENSE",
    transaction_date: "ISO 8601 string",  // ✅ FRONTEND SENDS CORRECTLY
    due_date: "YYYY-MM-DD" | null,
    items: [
      {
        item_id: string | null,
        description: string,
        quantity: number,
        price: number
      }
    ],
    subtotal_amount: number,
    total_gst_amount: number,
    total_amount: number
  }
  ```
- **Backend Response**:
  ```javascript
  {
    success: true,
    message: "Business transaction created successfully",
    data: { /* transaction with items and party */ }
  }
  ```

### 2. Get All Business Transactions
- **Frontend**: `GET /expenses/allBusinessTransactions`
- **Backend**: `GET /allBusinessTransactions` ✅ MATCH
- **Query Params**: `page`, `limit`, `business_id`, `transaction_type`, `start_date`, `end_date`
- **Backend Response**:
  ```javascript
  {
    success: true,
    data: [...],
    pagination: {
      page: number,
      limit: number,
      total: number,
      total_pages: number
    }
  }
  ```
- **Note**: Backend formats `transaction_date` as `YYYY-MM-DD` and `transaction_time` as `HH:mm`

### 3. Update Business Transaction
- **Frontend**: `PUT /expenses/businessTransaction/:id` ✅ FIXED
- **Backend**: `PUT /businessTransaction/:id` ✅ MATCH
- **Request Body**: Same as create
- **Backend Response**:
  ```javascript
  {
    success: true,
    message: "Business transaction updated successfully",
    data: { /* updated transaction */ }
  }
  ```

### 4. Delete Business Transaction
- **Frontend**: `DELETE /expenses/businessTransaction/:id` ✅ FIXED
- **Backend**: `DELETE /businessTransaction/:id` ✅ MATCH
- **Backend**: Soft delete (sets `is_deleted: true`)

---

## Critical Issues Found

### Issue #1: Personal Transaction Date/Time Format ⚠️
**Problem**: 
- Frontend sends: `transaction_date: "2024-01-15T14:30:00.000Z"` (ISO string with time)
- Backend expects: Separate `transaction_date: "YYYY-MM-DD"` and `transaction_time: "HH:mm"`

**Impact**: Update operations may fail or not properly save time

**Solution**: Split the datetime into separate fields before sending to backend

### Issue #2: Response Wrapper Not Unwrapped ⚠️
**Problem**: 
- Backend wraps all responses in `{ success, message, data }`
- Frontend expects direct data or different structure

**Impact**: Frontend may not properly parse responses

**Solution**: Update frontend to unwrap responses or update backend to return direct data

### Issue #3: Business Transaction EXPENSE Type Missing Fields ⚠️
**Problem**: 
- Backend (line 733-738) returns minimal fields for EXPENSE transactions
- No `party` or `items` included in response

**Impact**: Edit form won't have party/items data for EXPENSE transactions

**Solution**: Update backend to include all fields or handle missing fields in frontend

---

## Recommendations

1. **Fix Personal Transaction Date/Time**: Split datetime before sending to backend
2. **Update Response Handling**: Unwrap backend responses in frontend
3. **Add transaction_time field**: Frontend should send separate time field for personal transactions
4. **Test Business EXPENSE**: Ensure all fields are returned for EXPENSE type business transactions