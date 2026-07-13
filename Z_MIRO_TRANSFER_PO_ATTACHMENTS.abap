FUNCTION z_miro_transfer_po_attachments.
*"----------------------------------------------------------------------
*"*"Update Function Module:
*"
*"  IMPORTING
*"     VALUE(IV_BELNR) TYPE  RE_BELNR
*"     VALUE(IV_GJAHR) TYPE  GJAHR
*"     VALUE(IT_EBELN) TYPE  MMPUR_T_EBELN
*"----------------------------------------------------------------------
  DATA: ls_source_obj TYPE sibflporb,
        ls_target_obj TYPE sibflporb,
        lt_links      TYPE obl_t_link,
        ls_link       TYPE obl_s_link,
        lt_relopt     TYPE obl_t_relt,
        ls_relopt     TYPE obl_s_relt,
        lv_po_number  TYPE ebeln,
        ls_po         LIKE LINE OF it_ebeln.
  " Construct Target Object (MIRO Invoice - BUS2081)
  ls_target_obj-instid = iv_belnr && iv_gjahr. 
  ls_target_obj-typeid = 'BUS2081'.
  ls_target_obj-catid  = 'BO'.
  " Filter set for Attachments ('ATTA')
  ls_relopt-sign   = 'I'.
  ls_relopt-option = 'EQ'.
  ls_relopt-low    = 'ATTA'.
  APPEND ls_relopt TO lt_relopt.
  LOOP AT it_ebeln INTO ls_po.
    
    " Extract PO Number from the range table's LOW field
    lv_po_number = ls_po-low. 
    " Construct Source Object (Purchase Order - BUS2012)
    ls_source_obj-instid = lv_po_number.
    ls_source_obj-typeid = 'BUS2012'.
    ls_source_obj-catid  = 'BO'.
    " Read existing attachments from the PO
    TRY.
        CALL METHOD cl_binary_relation=>read_links
          EXPORTING
            is_object           = ls_source_obj
            it_relation_options = lt_relopt
          IMPORTING
            et_links            = lt_links.
      CATCH cx_root.
        CONTINUE.
    ENDTRY.
    " Link each physical document to the new MIRO object
    LOOP AT lt_links INTO ls_link.
      DATA(ls_doc_obj) = VALUE sibflporb( instid = ls_link-instid_b
                                          typeid = ls_link-typeid_b
                                          catid  = ls_link-catid_b ).
      TRY.
          CALL METHOD cl_binary_relation=>create_link
            EXPORTING
              is_object_a = ls_target_obj
              is_object_b = ls_doc_obj
              ip_reltype  = 'ATTA'.
        CATCH cx_root.
          " Ignore exceptions arising from duplicate linkages
          CONTINUE.
      ENDTRY.
    ENDLOOP.
  ENDLOOP.
ENDFUNCTION.
