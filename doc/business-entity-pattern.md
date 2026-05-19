# ABL Business Entity Architecture Pattern

## Overview

The Business Entity pattern provides a standardized, maintainable approach to data access in OpenEdge ABL applications. It separates UI logic from database operations through a layered architecture that promotes reusability, testability, and consistency across the application.

## Architecture Layers

### 1. UI Layer (Windows/Forms)
- **Responsibility**: User interaction and presentation
- **Access**: Never directly accesses database tables
- **Communication**: Calls Business Entity methods with datasets

### 2. Business Entity Layer
- **Responsibility**: Data access, business rules, validation
- **Inheritance**: Extends `OpenEdge.BusinessLogic.BusinessEntity`
- **Management**: Instantiated through EntityFactory (singleton pattern)

### 3. Database Layer
- **Responsibility**: Persistent storage
- **Access**: Only through data-sources attached to business entities

## Key Components

### EntityFactory (Singleton Pattern)

**Purpose**: Centralized management of business entity lifecycle

**Pattern**:
```abl
CLASS business.EntityFactory:
    /* Singleton instance */
    VAR PRIVATE STATIC EntityFactory objInstance.
    
    /* Entity instances */
    VAR PRIVATE CustomerEntity objCustomerEntityInstance.
    
    /* Private constructor prevents direct instantiation */
    CONSTRUCTOR PRIVATE EntityFactory():
    END CONSTRUCTOR.
    
    /* Public factory method */
    METHOD PUBLIC STATIC EntityFactory GetInstance():
        IF objInstance = ? THEN
            objInstance = NEW EntityFactory().
        RETURN objInstance.
    END METHOD.
    
    /* Entity getters with lazy initialization */
    METHOD PUBLIC CustomerEntity GetCustomerEntity():
        IF objCustomerEntityInstance = ? THEN
            objCustomerEntityInstance = NEW CustomerEntity().
        RETURN objCustomerEntityInstance.
    END METHOD.
END CLASS.
```

**Benefits**:
- Single source of truth for entity instances
- Prevents memory waste from duplicate objects
- Enables centralized cleanup and testing

### Dataset Definition (.i Include Files)

**Purpose**: Defines temp-tables and datasets for data transfer

**Pattern**:
```abl
/* Define temp-table with BEFORE-TABLE for change tracking */
DEFINE TEMP-TABLE ttCustomer BEFORE-TABLE bttCustomer
    FIELD CustNum AS INTEGER INITIAL "0" LABEL "Cust Num"
    FIELD Name AS CHARACTER LABEL "Name"
    FIELD Address AS CHARACTER LABEL "Address"
    /* ... additional fields ... */
    INDEX CustNum IS PRIMARY UNIQUE CustNum ASCENDING.

/* Define dataset containing the temp-table */
DEFINE DATASET dsCustomer FOR ttCustomer.
```

**Key Points**:
- `BEFORE-TABLE` enables change tracking for updates
- Temp-table fields match database table structure
- Primary index mirrors database primary key
- Shared via include file for consistency

### Business Entity Class

**Purpose**: Encapsulates all data operations for a specific entity

**Pattern**:
```abl
CLASS business.CustomerEntity INHERITS BusinessEntity USE-WIDGET-POOL:
    
    /* Include dataset definition */
    {business/CustomerDataset.i}
    
    /* Define data sources - one per database table */
    DEFINE DATA-SOURCE srcCustomer FOR Customer.
    
    CONSTRUCTOR PUBLIC CustomerEntity():
        /* Pass dataset handle to parent class */
        SUPER(DATASET dsCustomer:HANDLE).

        /* Create array of data source handles */
        VAR HANDLE[1] hDataSourceArray = DATA-SOURCE srcCustomer:HANDLE.
        VAR CHARACTER[1] cSkipListArray = [""].
        
        /* Set parent class properties */
        THIS-OBJECT:ProDataSource = hDataSourceArray.
        THIS-OBJECT:SkipList = cSkipListArray.
    END CONSTRUCTOR.
    
    /* Business methods follow... */
    
END CLASS.
```

**Critical Requirements**:
- Must inherit from `OpenEdge.BusinessLogic.BusinessEntity`
- Dataset handle passed to SUPER() constructor
- Data-source handles assigned to ProDataSource property
- SkipList array matches data-source array length

## Standard CRUD Operations

### Read (Query) Operations

**Pattern**:
```abl
METHOD PUBLIC LOGICAL GetCustomerByNumber(INPUT ipiCustNum AS INTEGER,
                                          OUTPUT DATASET dsCustomer):
    VAR CHARACTER cFilter.
    VAR LOGICAL lFound = FALSE.
    
    /* Build WHERE clause for database query */
    cFilter = "WHERE Customer.CustNum = " + STRING(ipiCustNum).
    
    /* Parent class ReadData() executes query and fills temp-table */
    THIS-OBJECT:ReadData(cFilter).

    /* Check if data was found */
    lFound = CAN-FIND(FIRST ttCustomer).
    
    RETURN lFound.
END METHOD.
```

**Key Points**:
- Use `OUTPUT DATASET` parameter (NOT `BY-REFERENCE`)
- Build filter as string with WHERE clause
- Call parent's `ReadData()` method
- Verify results using temp-table
- Return success/failure indicator

**Why NOT BY-REFERENCE for OUTPUT DATASET**:
- `BusinessEntity.ReadData()` fills the internal ProDataSet handle
- OUTPUT without BY-REFERENCE automatically copies data back to caller
- BY-REFERENCE can create handle mismatch issues
- The OUTPUT mechanism is the expected pattern for this architecture

### Create Operations

**Pattern**:
```abl
METHOD PUBLIC VOID CreateCustomer(INPUT-OUTPUT DATASET dsCustomer):
    /* Caller populates temp-table with new record */
    /* Parent class handles database insert */
    THIS-OBJECT:CreateData(DATASET dsCustomer BY-REFERENCE).
END METHOD.
```

### Update Operations

**Pattern**:
```abl
METHOD PUBLIC VOID UpdateCustomer(INPUT-OUTPUT DATASET dsCustomer):
    /* Parent class detects changes and updates database */
    THIS-OBJECT:UpdateData(DATASET dsCustomer BY-REFERENCE).
END METHOD.
```

**Critical Steps**:
1. Fetch current data using OUTPUT DATASET
2. Enable TRACKING-CHANGES on temp-table
3. Modify temp-table fields
4. Validate changes
5. Call UpdateData() with BY-REFERENCE

### Delete Operations

**Pattern**:
```abl
METHOD PUBLIC VOID DeleteCustomer(INPUT-OUTPUT DATASET dsCustomer):
    /* Parent class processes deletion */
    THIS-OBJECT:DeleteData(DATASET dsCustomer BY-REFERENCE).
END METHOD.
```

## Validation Pattern

**Pattern**:
```abl
METHOD PUBLIC LOGICAL ValidateCustomer(INPUT-OUTPUT DATASET dsCustomer,
                                     OUTPUT errorMessage AS CHARACTER):
    VAR LOGICAL isValid = TRUE.
    
    /* Find the record to validate */
    FIND FIRST ttCustomer NO-ERROR.
    IF AVAILABLE ttCustomer THEN DO:
        /* Check business rules */
        IF ttCustomer.Name = "" THEN DO:
            isValid = FALSE.
            errorMessage = "Customer name cannot be empty".
        END.
    END.
    
    RETURN isValid.
END METHOD.
```

## Common Pitfalls and Solutions

### Pitfall 1: Using BY-REFERENCE on OUTPUT DATASET for Read Operations

**Problem**:
```abl
/* WRONG - BY-REFERENCE on OUTPUT causes handle mismatch */
lFound = objEntity:GetCustomerByNumber(iNum, OUTPUT DATASET dsCustomer BY-REFERENCE).
```

**Solution**:
```abl
/* CORRECT - OUTPUT without BY-REFERENCE */
lFound = objEntity:GetCustomerByNumber(iNum, OUTPUT DATASET dsCustomer).
```

### Pitfall 2: Forgetting Change Tracking for Updates

**Problem**:
```abl
/* WRONG - Change tracking not enabled */
FIND FIRST ttCustomer.
ttCustomer.Name = "New Name".
objEntity:UpdateCustomer(INPUT-OUTPUT DATASET dsCustomer BY-REFERENCE).
/* Changes not detected! */
```

**Solution**:
```abl
/* CORRECT - Enable change tracking before modifications */
TEMP-TABLE ttCustomer:TRACKING-CHANGES = TRUE.
FIND FIRST ttCustomer.
ttCustomer.Name = "New Name".
objEntity:UpdateCustomer(INPUT-OUTPUT DATASET dsCustomer BY-REFERENCE).
```

### Pitfall 3: Not Using Named Buffers

**Problem**:
```abl
/* WRONG - Using table directly without buffer */
FOR EACH Customer WHERE Customer.Country = 'USA':
    /* ... */
END.
```

**Solution**:
```abl
/* CORRECT - Always use named buffers */
DEFINE BUFFER bCustomer FOR Customer.

FOR EACH bCustomer WHERE bCustomer.Country = 'USA':
    /* ... */
END.
```

## Benefits of This Architecture

### Maintainability
- Centralized data access logic
- Changes in one place affect all consumers
- Clear separation of concerns

### Reusability
- Business entities shared across multiple UI components
- Validation logic not duplicated
- Factory pattern enables easy testing

### Testability
- Business logic isolated from UI
- Can test entity methods independently
- Mock data sources for unit testing

### Consistency
- All data access follows same pattern
- Standard error handling
- Uniform validation approach

## References

- OpenEdge Documentation: Business Entity Class
- ABL Reference: Dataset and Temp-Table Definitions
- Design Patterns: Factory and Singleton patterns
- Project Examples:
  - `src/business/CustomerEntity.cls`
  - `src/business/EntityFactory.cls`
  - `src/CustomerWin.w`
