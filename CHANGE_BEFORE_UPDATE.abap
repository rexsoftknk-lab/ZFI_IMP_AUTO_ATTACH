METHOD if_ex_invoice_update~change_before_update.
  " Extract Invoice number and Fiscal year
  DATA: lv_belnr TYPE re_belnr,
        lv_gjahr TYPE gjahr.
  lv_belnr = s_rbkp_new-belnr.
  lv_gjahr = s_rbkp_new-gjahr.
  " Range table and work area declaration
  DATA: lt_ebeln TYPE mmpur_t_ebeln,
        ls_ebeln LIKE LINE OF lt_ebeln.
  " Collect all PO numbers from the line items into a range table format
  LOOP AT ti_mrmrseg INTO DATA(ls_rseg) WHERE ebeln IS NOT INITIAL.
    ls_ebeln-sign   = 'I'.
    ls_ebeln-option = 'EQ'.
    ls_ebeln-low    = ls_rseg-ebeln.
    APPEND ls_ebeln TO lt_ebeln.
    CLEAR ls_ebeln.
  ENDLOOP.
  " Sort and delete adjacent duplicates based on the LOW field
  SORT lt_ebeln BY low.
  DELETE ADJACENT DUPLICATES FROM lt_ebeln COMPARING low.
  IF lt_ebeln IS NOT INITIAL.
    " Query the EKKO table to filter ONLY 'ZTM' PO Document Types
    SELECT ebeln FROM ekko
      INTO TABLE @DATA(lt_ztm_pos)
      WHERE ebeln IN @lt_ebeln
        AND bsart = 'ZTM'.
    " If ZTM POs are found, rebuild the range table with only the valid ones
    IF sy-subrc = 0 AND lt_ztm_pos IS NOT INITIAL.
      CLEAR lt_ebeln. 
      
      LOOP AT lt_ztm_pos INTO DATA(ls_ztm_po).
        ls_ebeln-sign   = 'I'.
        ls_ebeln-option = 'EQ'.
        ls_ebeln-low    = ls_ztm_po-ebeln.
        APPEND ls_ebeln TO lt_ebeln.
      ENDLOOP.
      " Call the Update Task FM with the filtered ZTM POs
      CALL FUNCTION 'Z_MIRO_TRANSFER_PO_ATTACHMENTS' IN UPDATE TASK
        EXPORTING
          iv_belnr = lv_belnr
          iv_gjahr = lv_gjahr
          it_ebeln = lt_ebeln.
    ENDIF.
  ENDIF.
ENDMETHOD.
