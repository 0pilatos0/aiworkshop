/*------------------------------------------------------------------------
  File        : ItemEntity
  Purpose     : Business Entity for Item data access
  Syntax      : business.ItemEntity
  Description : Encapsulates Item read, update, and validation logic
  Author(s)   : Paul van der lei
  Created     : Tue May 19 12:15:00 UTC 2026
  Notes       : 
----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING OpenEdge.BusinessLogic.BusinessEntity.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS business.ItemEntity INHERITS BusinessEntity USE-WIDGET-POOL:

    /* Include dataset definition */
    {business/ItemDataset.i}

    /* Define data sources */
    DEFINE DATA-SOURCE srcItem FOR Item.

    /*------------------------------------------------------------------------------
     Purpose: Constructor for ItemEntity
     Notes:
    ------------------------------------------------------------------------------*/
    CONSTRUCTOR PUBLIC ItemEntity():
        SUPER(DATASET dsItem:HANDLE).

        VAR HANDLE[1]    hDataSourceArray = DATA-SOURCE srcItem:HANDLE.
        VAR CHARACTER[1] cSkipListArray   = [""].

        /* Data Source for each table in dataset */
        THIS-OBJECT:ProDataSource = hDataSourceArray.
        /* Skip-list entry for each table in dataset */
        THIS-OBJECT:SkipList = cSkipListArray.
    END CONSTRUCTOR.

    /*------------------------------------------------------------------------------
     Purpose: Get item by item number
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC LOGICAL GetItemByNumber(INPUT ipiItemNum AS INTEGER,
                                          OUTPUT DATASET dsItem):
        VAR CHARACTER cFilter.
        VAR LOGICAL   lFound = FALSE.

        cFilter = "WHERE Item.ItemNum = " + STRING(ipiItemNum).

        THIS-OBJECT:ReadData(cFilter).

        lFound = CAN-FIND(FIRST ttItem).

        RETURN lFound.
    END METHOD.

    /*------------------------------------------------------------------------------
     Purpose: Update item data
     Notes:
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC VOID UpdateItem(INPUT-OUTPUT DATASET dsItem):
        THIS-OBJECT:UpdateData(DATASET dsItem BY-REFERENCE).
    END METHOD.

    /*------------------------------------------------------------------------------
     Purpose: Validate item data
     Notes:   Returns FALSE and sets errorMessage when validation fails
    ------------------------------------------------------------------------------*/
    METHOD PUBLIC LOGICAL ValidateItem(INPUT-OUTPUT DATASET dsItem,
                                       OUTPUT errorMessage AS CHARACTER):
        VAR LOGICAL lValid = TRUE.

        FIND FIRST ttItem NO-ERROR.
        IF AVAILABLE ttItem THEN DO:
            IF ttItem.Price = 0 THEN DO:
                lValid       = FALSE.
                errorMessage = "Price cannot be empty".
                RETURN lValid.
            END.

            IF ttItem.OnHand * ttItem.Price > 6000 THEN DO:
                lValid       = FALSE.
                errorMessage = "Total value onhand will be "
                             + STRING(ttItem.OnHand * ttItem.Price)
                             + ", should not be larger than 6000".
            END.
        END.

        RETURN lValid.
    END METHOD.

END CLASS.
