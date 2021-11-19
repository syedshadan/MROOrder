    CLASS lhc_c_maintorder DEFINITION INHERITING FROM cl_abap_behavior_handler.
      PRIVATE SECTION.

        METHODS read FOR READ
          IMPORTING keys FOR READ /gen3apps/c_maintorder RESULT result.

        METHODS change_responsibility FOR MODIFY
          IMPORTING keys FOR ACTION /gen3apps/c_maintorder~change_responsibility.

        METHODS release FOR MODIFY
          IMPORTING keys FOR ACTION /gen3apps/c_maintorder~release RESULT result .

        METHODS do_not_execute FOR MODIFY
          IMPORTING keys FOR ACTION /gen3apps/c_maintorder~do_not_execute.

        METHODS complete_technically FOR MODIFY
          IMPORTING keys FOR ACTION /gen3apps/c_maintorder~complete_technically .

        METHODS complete_business FOR MODIFY
          IMPORTING keys FOR ACTION /gen3apps/c_maintorder~complete_business  .

        METHODS cancel_business_comp FOR MODIFY
          IMPORTING keys FOR ACTION /gen3apps/c_maintorder~cancel_business_comp RESULT result.

        METHODS cancel_tech_completion FOR MODIFY
          IMPORTING keys FOR ACTION /gen3apps/c_maintorder~cancel_tech_completion.

        METHODS change_schedule FOR MODIFY
          IMPORTING keys FOR ACTION /gen3apps/c_maintorder~change_schedule.

        METHODS assign_network FOR MODIFY
          IMPORTING keys FOR ACTION /gen3apps/c_maintorder~assign_network.

        METHODS update_task_list FOR MODIFY
          IMPORTING keys FOR ACTION /gen3apps/c_maintorder~update_task_list.

        METHODS get_features FOR FEATURES
          IMPORTING keys REQUEST requested_features FOR /gen3apps/c_maintorder RESULT result.

    ENDCLASS.

    CLASS lhc_c_maintorder IMPLEMENTATION.

      METHOD read.
*        method implement for dynamic features of disabling/enabling  action buttons on UI
*        using the below 'get_features' method

        CONSTANTS : lc_tab_c_maintorder TYPE tabname VALUE '/GEN3APPS/C_MAINTORDER'.  "Added for P2 Correction

        DATA lv_whitelist TYPE string.                 "Added for P2 Correction
        DATA lv_table_str TYPE string.                 "Added for P2 Correction
        DATA ls_data TYPE /gen3apps/c_maintorder. "Added for P2 Correction

        LOOP AT keys INTO DATA(ls_keys).

*SOC Added for P2 correction

          TRY .
              CLEAR lv_whitelist. CLEAR lv_table_str.
              lv_whitelist = lv_table_str = lc_tab_c_maintorder.
              lv_table_str = cl_abap_dyn_prg=>check_whitelist_str(
                   val = lv_table_str  whitelist = lv_whitelist ).
            CATCH cx_abap_not_in_whitelist.
          ENDTRY.

          SELECT SINGLE * FROM (lv_table_str) INTO @ls_data
                   WHERE maintenanceorder = @ls_keys-maintenanceorder.

*            SELECT SINGLE * FROM /gen3apps/c_maintorder INTO @DATA(ls_data)
*                     WHERE maintenanceorder = @ls_keys-maintenanceorder.

**EOC for P2 correction on 7/6/2021

          "fill result parameter with flagged fields
          INSERT CORRESPONDING #( ls_data ) INTO TABLE result.

        ENDLOOP.
      ENDMETHOD.
**************************************End Of Method READ***********************************************

      METHOD change_responsibility.

*        CONSTANTS: lc_parvw_vera TYPE char2 VALUE 'VW'.

        DATA: lt_return   TYPE bapirettab,
              lt_messages TYPE stty_message,
              ls_messages TYPE sstr_message,
              lv_aufnr    TYPE aufnr,
              ls_return1  TYPE bapiret2.

        DATA  ls_chg_responsibility       TYPE /gen3apps/chg_responsibility_s.
        DATA lo_order TYPE REF TO /gen3apps/cl_order_bo.

        CREATE OBJECT lo_order.

        LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_entities>).

          lv_aufnr = <fs_entities>-maintenanceorder.

          SHIFT lv_aufnr LEFT DELETING LEADING '0'.

          " Filling importing structure for method call
          ls_chg_responsibility-maintenanceorder           = <fs_entities>-maintenanceorder.
          ls_chg_responsibility-maintenanceplannergroup    = <fs_entities>-%param-maintenanceplannergroup.
          ls_chg_responsibility-maintordpersonresponsible  = <fs_entities>-%param-maintordpersonresponsible.
          ls_chg_responsibility-mainworkcenter             = <fs_entities>-%param-mainworkcenter.
          ls_chg_responsibility-mainworkcenterplant        = <fs_entities>-%param-mainworkcenterplant.

          " Calling Method for order action Change Responsibility
          CALL METHOD lo_order->change_responsibility
            EXPORTING
              is_change_responsibility = ls_chg_responsibility
            IMPORTING
              et_return                = lt_return.

          READ TABLE lt_return INTO ls_return1 WITH KEY type = 'S'.

          IF sy-subrc = 0. " if success msg

            "checking BAPI return structure
            LOOP AT lt_return INTO DATA(ls_return).
              ls_messages-type       = ls_return-type.
              ls_messages-id         = ls_return-id.
              ls_messages-number     = ls_return-number.
              ls_messages-message_v1 = lv_aufnr.
              APPEND ls_messages TO lt_messages.
              CLEAR ls_messages.
            ENDLOOP.

            SORT lt_messages BY type.
            DELETE ADJACENT DUPLICATES FROM lt_messages COMPARING type.

          ELSE. " if error msg from BAPI then display the same at UI
            lt_messages = CORRESPONDING #( lt_return ).
          ENDIF.
          CLEAR ls_chg_responsibility.

        ENDLOOP.


        "Message Handling in Enabler APPs
        IF lt_messages IS NOT INITIAL.
          /gen3apps/cl_mro_order_msg_han=>handle_messages(
                    EXPORTING
                    it_messages = lt_messages
                  CHANGING
                  failed = failed-/gen3apps/c_maintorder
                  mapped = mapped-/gen3apps/c_maintorder
                  reported = reported-/gen3apps/c_maintorder
                    ).
        ENDIF.

      ENDMETHOD.
**************************************End Of Method Change_Responsibility******************************


      METHOD release.

        DATA: lt_return   TYPE STANDARD TABLE OF bapiret2,
              lt_messages TYPE stty_message,
              ls_messages TYPE sstr_message,
              lv_aufnr    TYPE aufnr.

        DATA lo_order TYPE REF TO /gen3apps/cl_order_bo.

        CREATE OBJECT lo_order.

        LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_entities>).

          lv_aufnr = <fs_entities>-maintenanceorder.

          SHIFT lv_aufnr LEFT DELETING LEADING '0'.

          CALL METHOD lo_order->release_order
            EXPORTING
              iv_maint_order = <fs_entities>-maintenanceorder
            IMPORTING
              et_return      = lt_return.

          "checking BAPI return structure and updating message accordingly
          LOOP AT lt_return INTO DATA(ls_return) .
            IF ls_return-type = 'S'.
              ls_messages-type       = ls_return-type.
              ls_messages-id         = 'EAM_ODATA_ORDER'.
              ls_messages-number     = 100.
              ls_messages-message_v1 = lv_aufnr.
            ELSE.
              ls_messages-type       = ls_return-type.
              ls_messages-id         = ls_return-id.
              ls_messages-number     = ls_return-number.
              ls_messages-message_v1 = lv_aufnr.
            ENDIF.
            APPEND ls_messages TO lt_messages.
            CLEAR ls_messages.
          ENDLOOP.

          SORT lt_messages BY type.
          DELETE ADJACENT DUPLICATES FROM lt_messages COMPARING type.
        ENDLOOP.

        "Message Handling in Enabler APPs
        IF lt_messages IS NOT INITIAL.
          /gen3apps/cl_mro_order_msg_han=>handle_messages(
                    EXPORTING
                    it_messages = lt_messages
                  CHANGING
                  failed = failed-/gen3apps/c_maintorder
                  mapped = mapped-/gen3apps/c_maintorder
                  reported = reported-/gen3apps/c_maintorder
                    ).
        ENDIF.
      ENDMETHOD.
**************************************End Of Method Release**********************************************

      METHOD do_not_execute .

        DATA : lt_return   TYPE STANDARD TABLE OF bapiret2,
               lt_messages TYPE stty_message,
               ls_messages TYPE sstr_message,
               lv_aufnr    TYPE aufnr.

        DATA lo_order TYPE REF TO /gen3apps/cl_order_bo.

        CREATE OBJECT lo_order.

        LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_entities>).

          lv_aufnr = <fs_entities>-maintenanceorder.

          SHIFT lv_aufnr LEFT DELETING LEADING '0'.

          CALL METHOD lo_order->do_not_execute
            EXPORTING
              iv_maintenanceorder = <fs_entities>-maintenanceorder
              iv_actionname       = <fs_entities>-%param-actionname
            IMPORTING
              et_return           = lt_return.

          "checking BAPI return structure
          LOOP AT lt_return INTO DATA(ls_return) .
            IF ls_return-type = 'S'.
              ls_messages-type       = ls_return-type.
              ls_messages-id         = 'EAM_ODATA_ORDER'.
              ls_messages-number     = 105.
              ls_messages-message_v1 = lv_aufnr.
            ELSE.
              ls_messages-type       = ls_return-type.
              ls_messages-id         = ls_return-id.
              ls_messages-number     = ls_return-number.
              ls_messages-message_v1 = lv_aufnr.
            ENDIF.
            APPEND ls_messages TO lt_messages.
            CLEAR ls_messages.
          ENDLOOP.

          SORT lt_messages BY type.
          DELETE ADJACENT DUPLICATES FROM lt_messages COMPARING type.
        ENDLOOP.

        "Message Handling in Enabler APPs
        IF lt_messages IS NOT INITIAL.
          /gen3apps/cl_mro_order_msg_han=>handle_messages(
                     EXPORTING
                     it_messages = lt_messages
                   CHANGING
                   failed = failed-/gen3apps/c_maintorder
                   mapped = mapped-/gen3apps/c_maintorder
                   reported = reported-/gen3apps/c_maintorder
                     ).
        ENDIF.
      ENDMETHOD.
**************************************End Of Method DO_NOT_EXECUTE*************************************

      METHOD complete_technically.   "check head_up

        DATA : lt_return   TYPE STANDARD TABLE OF bapiret2,
               lt_messages TYPE stty_message,
               ls_messages TYPE sstr_message,
               lv_aufnr    TYPE aufnr.

        DATA ls_tech_comp TYPE /gen3apps/tech_comp_s.  "
        DATA lo_order TYPE REF TO /gen3apps/cl_order_bo.
        CREATE OBJECT lo_order.

        LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_entities>).

          lv_aufnr = <fs_entities>-maintenanceorder.

          SHIFT lv_aufnr LEFT DELETING LEADING '0'.

          " Filling importing structure for method call
          ls_tech_comp-orderno         = <fs_entities>-maintenanceorder.
*          ls_tech_comp-actionname      = COND #( WHEN <fs_entities>-%param-actionname = abap_true
*                                                 THEN if_eams3_bo_ord_status_const=>gc_status_action-set_teco_with_notif
*                                                 ELSE cl_eams_mp_ordntf=>gc_action_id-set_status_ord_complete_tec ).

           ls_tech_comp-actionname      = <fs_entities>-%param-actionname.   "Added for action name
          ls_tech_comp-lastchangedate  = <fs_entities>-%param-lastchangedate.
          ls_tech_comp-lastchangetime  = <fs_entities>-%param-lastchangetime.

          "calling method for technically completing an order
          CALL METHOD lo_order->technically_complete
            EXPORTING
              is_tech_comp = ls_tech_comp
            IMPORTING
              et_return    = lt_return.

          "checking BAPI return structure
          LOOP AT lt_return INTO DATA(ls_return) .
            IF ls_return-type        = 'S'.
              ls_messages-type       = ls_return-type.
              ls_messages-id         = 'EAM_ODATA_ORDER'.
              ls_messages-number     = 101.
              ls_messages-message_v1 = lv_aufnr.
            ELSE.
              ls_messages-type       = ls_return-type.
              ls_messages-id         = ls_return-id.
              ls_messages-number     = ls_return-number.
              ls_messages-message_v1 = lv_aufnr.
            ENDIF.
            APPEND ls_messages TO lt_messages.
            CLEAR ls_messages.
          ENDLOOP.

          SORT lt_messages BY type.
          DELETE ADJACENT DUPLICATES FROM lt_messages COMPARING type.
          CLEAR ls_tech_comp.

        ENDLOOP.
        "Message Handling in Enabler APPs
        IF lt_messages IS NOT INITIAL.
          /gen3apps/cl_mro_order_msg_han=>handle_messages(
                    EXPORTING
                    it_messages = lt_messages
                  CHANGING
                  failed = failed-/gen3apps/c_maintorder
                  mapped = mapped-/gen3apps/c_maintorder
                  reported = reported-/gen3apps/c_maintorder
                    ).
        ENDIF.
      ENDMETHOD.
**************************************End Of Method Complete_technically*******************************


      METHOD complete_business.

        DATA : lt_return   TYPE STANDARD TABLE OF bapiret2,
               lt_messages TYPE stty_message,
               ls_messages TYPE sstr_message,
               lv_aufnr    TYPE aufnr.

        DATA   ls_business_comp       TYPE  /gen3apps/tech_comp_s.

        DATA lo_order TYPE REF TO /gen3apps/cl_order_bo.
        CREATE OBJECT lo_order.

        CLEAR lt_messages.

        LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_entities>).

          lv_aufnr = <fs_entities>-maintenanceorder.

          SHIFT lv_aufnr LEFT DELETING LEADING '0'.

          " Filling importing structure for method call
          ls_business_comp-orderno         = <fs_entities>-maintenanceorder .
*          ls_business_comp-actionname      = COND #( WHEN <fs_entities>-%param-actionname = abap_true THEN 'BUS_COMPL_WITH_NOTIF'
*                                                     ELSE 'COMPLETE_BUSINESS' ).
             ls_business_comp-actionname      = <fs_entities>-%param-actionname.   "Added for action name
          ls_business_comp-lastchangedate  = <fs_entities>-%param-lastchangedate.
          ls_business_comp-lastchangetime  = <fs_entities>-%param-lastchangetime.

          " Calling Method for order action COMPLETE_BUSINESS
          CALL METHOD lo_order->complete_business
            EXPORTING
              is_business_comp = ls_business_comp
            IMPORTING
              et_return        = lt_return.

          "checking BAPI return structure
          LOOP AT lt_return INTO DATA(ls_return) .
            IF ls_return-type = 'S'.
              ls_messages-type       = ls_return-type.
              ls_messages-id         = 'EAM_ODATA_ORDER'.
              ls_messages-number     = 103.
              ls_messages-message_v1 = lv_aufnr.
            ELSE.
              ls_messages-type       = ls_return-type.
              ls_messages-id         = ls_return-id.
              ls_messages-number     = ls_return-number.
              ls_messages-message_v1 = lv_aufnr.
            ENDIF.
            APPEND ls_messages TO lt_messages.
            CLEAR ls_messages.
          ENDLOOP.

          SORT lt_messages BY type.
          DELETE ADJACENT DUPLICATES FROM lt_messages COMPARING type.
          CLEAR ls_business_comp.
        ENDLOOP.


        "Message Handling in Enabler APPs
        IF lt_messages IS NOT INITIAL.
          /gen3apps/cl_mro_order_msg_han=>handle_messages(
                    EXPORTING
                    it_messages = lt_messages
                  CHANGING
                  failed = failed-/gen3apps/c_maintorder
                  mapped = mapped-/gen3apps/c_maintorder
                  reported = reported-/gen3apps/c_maintorder
                    ).
        ENDIF.
      ENDMETHOD.
**************************************End Of Method COMPLETE_BUSINESS**********************************************


      METHOD cancel_tech_completion.

        DATA: lt_return   TYPE STANDARD TABLE OF bapiret2,
              lt_messages TYPE stty_message,
              ls_messages TYPE sstr_message,
              lv_aufnr    TYPE aufnr.

        DATA lo_order TYPE REF TO /gen3apps/cl_order_bo.
        CREATE OBJECT lo_order.

        LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_entities>).

          lv_aufnr = <fs_entities>-maintenanceorder.
          SHIFT lv_aufnr LEFT DELETING LEADING '0'.

          "calling Method To Cancel Technical Completion of an order
          CALL METHOD lo_order->cancel_tech_comp
            EXPORTING
              iv_maint_order = <fs_entities>-maintenanceorder
              iv_action_name = <fs_entities>-%param-actionname
            IMPORTING
              et_return      = lt_return.

          "checking BAPI return structure
          LOOP AT lt_return INTO DATA(ls_return) .
            IF ls_return-type        = 'S'.
              ls_messages-type       = ls_return-type.
              ls_messages-id         = 'EAM_ODATA_ORDER'.
              ls_messages-number     = 102.
              ls_messages-message_v1 = lv_aufnr.
            ELSE.
              ls_messages-type       = ls_return-type.
              ls_messages-id         = ls_return-id.
              ls_messages-number     = ls_return-number.
              ls_messages-message_v1 = lv_aufnr.
            ENDIF.
            APPEND ls_messages TO lt_messages.
            CLEAR ls_messages.
          ENDLOOP.

          SORT lt_messages BY type.
          DELETE ADJACENT DUPLICATES FROM lt_messages COMPARING type.
        ENDLOOP.

        "Message Handling in Enabler APPs
        IF lt_messages IS NOT INITIAL.
          /gen3apps/cl_mro_order_msg_han=>handle_messages(
                     EXPORTING
                     it_messages = lt_messages
                   CHANGING
                   failed = failed-/gen3apps/c_maintorder
                   mapped = mapped-/gen3apps/c_maintorder
                   reported = reported-/gen3apps/c_maintorder
                     ).
        ENDIF.
      ENDMETHOD.
**************************************End Of Method Cancel_Tech_Completion****************************


      METHOD cancel_business_comp.

        DATA: lt_messages TYPE stty_message,
              ls_messages TYPE sstr_message,
              lt_return   TYPE STANDARD TABLE OF bapiret2,
              lv_aufnr    TYPE aufnr.

        DATA lo_order TYPE REF TO /gen3apps/cl_order_bo.
        CREATE OBJECT lo_order.

        LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_entities>).

          lv_aufnr = <fs_entities>-maintenanceorder.

          SHIFT lv_aufnr LEFT DELETING LEADING '0'.

          " Calling Method To Cancel Business Completion of an order
          CALL METHOD lo_order->cancel_business_comp
            EXPORTING
              iv_maint_order = <fs_entities>-maintenanceorder
            IMPORTING
              et_return      = lt_return.

          "checking BAPI return structure
          LOOP AT lt_return INTO DATA(ls_return) .
            IF ls_return-type        = 'S'.
              ls_messages-type       = ls_return-type.
              ls_messages-id         = 'EAM_ODATA_ORDER'.
              ls_messages-number     = 104.
              ls_messages-message_v1 = lv_aufnr.
            ELSE.
              ls_messages-type       = ls_return-type.
              ls_messages-id         = ls_return-id.
              ls_messages-number     = ls_return-number.
              ls_messages-message_v1 = lv_aufnr.
            ENDIF.
            APPEND ls_messages TO lt_messages.
            CLEAR ls_messages.
          ENDLOOP.

          SORT lt_messages BY type.
          DELETE ADJACENT DUPLICATES FROM lt_messages COMPARING type.

        ENDLOOP.
        "Message Handling in Enabler APPs
        IF lt_messages IS NOT INITIAL.
          /gen3apps/cl_mro_order_msg_han=>handle_messages(
                    EXPORTING
                    it_messages = lt_messages
                  CHANGING
                  failed = failed-/gen3apps/c_maintorder
                  mapped = mapped-/gen3apps/c_maintorder
                  reported = reported-/gen3apps/c_maintorder
                    ).
        ENDIF.
      ENDMETHOD.
**************************************End Of Method CANCEL_BUISNESS_COMPLETION************************

      METHOD change_schedule.

        DATA:lt_return   TYPE bapirettab,
             lt_messages TYPE stty_message,
             ls_messages TYPE sstr_message,
             lv_aufnr    TYPE aufnr.

        DATA ls_chg_schedule   TYPE /gen3apps/chg_schedule_s.
        DATA lo_order          TYPE REF TO /gen3apps/cl_order_bo.

        CREATE OBJECT lo_order.

        LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_entities>).

          lv_aufnr = <fs_entities>-maintenanceorder.

          SHIFT lv_aufnr LEFT DELETING LEADING '0'.

          " Filling importing structure for method call
          ls_chg_schedule-orderno                  = <fs_entities>-maintenanceorder.
          ls_chg_schedule-maintenancerevision      = <fs_entities>-%param-maintenancerevision.
          ls_chg_schedule-maintpriority            = <fs_entities>-%param-maintpriority.
          ls_chg_schedule-maintordbasicstartdate   = <fs_entities>-%param-maintordbasicstartdate.
          ls_chg_schedule-maintordbasicenddate     = <fs_entities>-%param-maintordbasicenddate.

          "Calling method to change schedule of an order
          CALL METHOD lo_order->change_schedule
            EXPORTING
              is_chg_schedule = ls_chg_schedule
            IMPORTING
              et_return       = lt_return.

          "checking BAPI return structure
          CLEAR lt_messages.
          lt_messages = CORRESPONDING #( lt_return ).

          SORT lt_messages BY type.
          DELETE ADJACENT DUPLICATES FROM lt_messages COMPARING type.
          CLEAR ls_chg_schedule.
        ENDLOOP.

        "Message Handling in Enabler APPs
        IF lt_messages IS NOT INITIAL.
          /gen3apps/cl_mro_order_msg_han=>handle_messages(
                    EXPORTING
                    it_messages = lt_messages
                  CHANGING
                  failed = failed-/gen3apps/c_maintorder
                  mapped = mapped-/gen3apps/c_maintorder
                  reported = reported-/gen3apps/c_maintorder ).
        ENDIF.

      ENDMETHOD.
**************************************End Of Method CHANGE_SCHEDULE************************************


      METHOD assign_network.

        DATA:
          lt_return   TYPE STANDARD TABLE OF bapiret2,
          lt_messages TYPE stty_message,
          ls_messages TYPE sstr_message,
          lv_aufnr    TYPE aufnr,
          ls_return1  TYPE bapiret2,
          lv_network  TYPE aufnr,
          lv_network1 TYPE aufnr.

        CONSTANTS : lc_tab_aufk        TYPE tabname VALUE 'AUFK'.  "Added for P2 Correction

        DATA lv_whitelist TYPE string.          "Added for P2 Correction
        DATA lv_table_str TYPE string.          "Added for P2 Correction
        DATA lo_order          TYPE REF TO /gen3apps/cl_order_bo.

        CREATE OBJECT lo_order.

        LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_entities>).

          "checking if its a valid network
          lv_network1 = <fs_entities>-%param-projectnetwork.

*SOC Added for P2 correction on 7/6/2021

          TRY .
              CLEAR lv_whitelist. CLEAR lv_table_str.
              lv_whitelist = lv_table_str = lc_tab_aufk.
              lv_table_str = cl_abap_dyn_prg=>check_whitelist_str(
                   val = lv_table_str  whitelist = lv_whitelist ).
            CATCH cx_abap_not_in_whitelist.
          ENDTRY.

*          SELECT SINGLE aufnr FROM aufk INTO lv_network WHERE aufnr = lv_network1.

          SELECT SINGLE aufnr FROM (lv_table_str) INTO lv_network WHERE aufnr = lv_network1.

**EOC for P2 correction on 7/6/2021

          IF sy-subrc = 0. "if network Valid

            lv_aufnr = <fs_entities>-maintenanceorder.

            SHIFT lv_aufnr LEFT DELETING LEADING '0'.

            CALL METHOD lo_order->assign_network
              EXPORTING
                iv_maintenanceorder = <fs_entities>-maintenanceorder
                iv_projectnetwork   = <fs_entities>-%param-projectnetwork
                iv_networkactivity  = <fs_entities>-%param-networkactivity
              IMPORTING
                et_return           = lt_return.

            " preparing messages to be displayed on UI
            READ TABLE lt_return INTO ls_return1 WITH KEY type = 'S'.

            IF sy-subrc = 0.

              LOOP AT lt_return INTO DATA(ls_return) .
                ls_messages-type       = ls_return-type.
                ls_messages-id         = ls_return-id.
                ls_messages-number     = ls_return-number.
                IF ls_return-id = 'CN' ."if meessage from NEtwork message class , pass network activity
                  ls_messages-message_v1 = <fs_entities>-%param-networkactivity.
                ELSE.
                  ls_messages-message_v1 = lv_aufnr.
                ENDIF.
                APPEND ls_messages TO lt_messages.
                CLEAR ls_messages.
              ENDLOOP.

              SORT lt_messages BY type.
              DELETE ADJACENT DUPLICATES FROM lt_messages COMPARING type.

            ELSE.
              lt_messages = CORRESPONDING #( lt_return ).
            ENDIF.

          ELSE. " if network not valid

            SHIFT lv_network1 LEFT DELETING LEADING '0'.

            CLEAR: ls_return, lt_return.
            ls_return-type       = 'E'.
            ls_return-id         = 'CN'.
            ls_return-number     = 212.
            ls_return-message_v1 = lv_network1.
            MESSAGE e212(cn) WITH lv_network1 INTO ls_return-message.
            APPEND ls_return TO lt_return.
            lt_messages = CORRESPONDING #( lt_return ).
          ENDIF.

        ENDLOOP.
        "Message Handling in Enabler APPs
        IF lt_messages IS NOT INITIAL.
          /gen3apps/cl_mro_order_msg_han=>handle_messages(
                    EXPORTING
                    it_messages = lt_messages
                  CHANGING
                  failed = failed-/gen3apps/c_maintorder
                  mapped = mapped-/gen3apps/c_maintorder
                  reported = reported-/gen3apps/c_maintorder
                    ).
        ENDIF.

      ENDMETHOD.

**************************************End Of Method ASSIGN_NETWORK**********************************************
      METHOD update_task_list.

        DATA: lv_order    TYPE aufnr,
              lv_type     TYPE plnty,
              lv_group    TYPE plnnr,
              lv_counter  TYPE plnal,
              ls_message  TYPE sstr_message,
              lt_messages TYPE stty_message,
              lt_method   TYPE STANDARD TABLE OF bapi_alm_order_method,
              lt_tasklist TYPE STANDARD TABLE OF bapi_alm_order_tasklists_i,
              lt_return   TYPE STANDARD TABLE OF bapiret2,
              lt_plkob    TYPE plkob_tt,
              wa_t412     TYPE t412.

        DATA ls_upd_task_list            TYPE /gen3apps/upd_task_list_s.
        DATA lo_order TYPE REF TO /gen3apps/cl_order_bo.
        CREATE OBJECT lo_order.

        CONSTANTS : lc_tab_t412        TYPE tabname VALUE 'T412'.  "Added for P2 Correction

        DATA lv_whitelist TYPE string.          "Added for P2 Correction
        DATA lv_table_str TYPE string.          "Added for P2 Correction

        LOOP AT keys ASSIGNING FIELD-SYMBOL(<fs_entities>).

          " Filling importing structure for method call
          ls_upd_task_list-maintenanceorder     = <fs_entities>-maintenanceorder.
          ls_upd_task_list-tasklistgroup        = <fs_entities>-%param-tasklistgroup.
          ls_upd_task_list-tasklistgroupcounter = <fs_entities>-%param-tasklistgroupcounter.
          ls_upd_task_list-tasklisttype         = <fs_entities>-%param-tasklisttype.

          CALL METHOD lo_order->update_task_list
            EXPORTING
              is_upd_task_list = ls_upd_task_list
            IMPORTING
              et_return        = lt_return.

          LOOP AT lt_return ASSIGNING FIELD-SYMBOL(<fs_return>).
            IF <fs_return>-type = 'S'.
              ls_message-type       = 'S'.
              ls_message-id         = '/GEN3APPS/MROORDER'.   "Order saved Successfully
              ls_message-number     = 000.
              ls_message-message_v1 = <fs_return>-message_v1.

            ELSE.
              ls_message-type       = <fs_return>-type.
              ls_message-id         = <fs_return>-id.
              ls_message-number     = <fs_return>-number.
              ls_message-message_v1 = <fs_return>-message_v1.
              ls_message-message_v2 = <fs_return>-message_v2.
              ls_message-message_v3 = <fs_return>-message_v3.
            ENDIF.
            APPEND ls_message TO lt_messages.
            CLEAR ls_upd_task_list.
          ENDLOOP.

        ENDLOOP.

        "message handling
        IF lt_messages IS NOT INITIAL.
          /gen3apps/cl_mro_order_msg_han=>handle_messages(
                    EXPORTING
                    it_messages = lt_messages
                  CHANGING
                  failed = failed-/gen3apps/c_maintorder
                  mapped = mapped-/gen3apps/c_maintorder
                  reported = reported-/gen3apps/c_maintorder
                    ).
        ENDIF.
*        ENDLOOP.

      ENDMETHOD.
**************************************End Of Method update_task_list**********************************************
      METHOD get_features.
*Processing Phase values
*   0   Outstanding
*   1   Postponed
*   2   Released
*   3   Technically Completed
*   4   Manual deletion Indicator set
*   5   Historical Order
*   6   Completed For Business

        READ ENTITY /gen3apps/c_maintorder
        FROM VALUE #( FOR keyval IN keys  ( %key = keyval-%key ) ) RESULT DATA(lt_result1).


        result = VALUE #( FOR ls_order IN lt_result1 ( %key = ls_order-%key
        %features-%action-change_responsibility   = COND #( WHEN ls_order-maintenanceprocessingphase = 0  OR  ls_order-maintenanceprocessingphase = 2
                                                    THEN if_abap_behv=>fc-o-enabled
                                                    ELSE if_abap_behv=>fc-o-disabled   )
        %features-%action-release                 = COND #( WHEN ls_order-maintenanceprocessingphase = 0
                                                    THEN if_abap_behv=>fc-o-enabled
                                                    ELSE if_abap_behv=>fc-o-disabled   )
*        %features-%action-do_not_execute          = COND #( WHEN ls_order-maintenanceprocessingphase = 0
*                                                    THEN if_abap_behv=>fc-o-enabled
*                                                    ELSE if_abap_behv=>fc-o-disabled   )
*  BOF Changes done on 17-june-2021
*        %features-%action-do_not_execute          = COND #( WHEN ls_order-maintenanceprocessingphase <> 0
*                                                             OR ls_order-OrdStat CP '*CRTD, MEBS*'
*                                                     THEN if_abap_behv=>fc-o-disabled
*                                                     ELSE if_abap_behv=>fc-o-enabled   )
        %features-%action-do_not_execute          = COND #( WHEN ls_order-maintenanceprocessingphase <> 0
                                                         OR ( ls_order-ordstat CP 'CRTD' AND ls_order-ordstat CP 'MEBS' )
                                                    THEN if_abap_behv=>fc-o-disabled
                                                    ELSE if_abap_behv=>fc-o-enabled   )
*     EOF Changes done on 17-june-2021

        %features-%action-complete_technically    = COND #( WHEN ls_order-maintenanceprocessingphase = 2
                                                    THEN if_abap_behv=>fc-o-enabled
                                                    ELSE if_abap_behv=>fc-o-disabled   )

*  BOF Changes done on 11-Mar-2021
*  For the time only Technical Complete --> Business Complete transition is allowed.
**      %features-%action-complete_business        = COND #( WHEN ls_order-maintenanceprocessingphase = 2  OR ls_order-maintenanceprocessingphase =   3
**                                                    THEN if_abap_behv=>fc-o-enabled
**                                                    ELSE if_abap_behv=>fc-o-disabled   )
        %features-%action-complete_business  = COND #( WHEN ls_order-maintenanceprocessingphase =   3
                                                    THEN if_abap_behv=>fc-o-enabled
                                                    ELSE if_abap_behv=>fc-o-disabled   )
*  EOF Changes done on 11-Mar-2021

         %features-%action-cancel_business_comp   = COND #( WHEN ls_order-maintenanceprocessingphase = 6 AND ls_order-dneordstat EQ space
                                                    THEN if_abap_behv=>fc-o-enabled
                                                    ELSE if_abap_behv=>fc-o-disabled   )
       %features-%action-cancel_tech_completion   = COND #( WHEN ls_order-maintenanceprocessingphase = 3
                                                    THEN if_abap_behv=>fc-o-enabled
                                                    ELSE if_abap_behv=>fc-o-disabled   )
              %features-%action-change_schedule   = COND #( WHEN ls_order-maintenanceprocessingphase = 0  OR ls_order-maintenanceprocessingphase =   2
                                                    THEN if_abap_behv=>fc-o-enabled
                                                    ELSE if_abap_behv=>fc-o-disabled   )
              %features-%action-assign_network   =  COND #( WHEN ls_order-maintenanceprocessingphase = 3  OR ls_order-maintenanceprocessingphase =   6
                                                    THEN if_abap_behv=>fc-o-disabled
                                                    ELSE if_abap_behv=>fc-o-enabled   )
              %features-%action-update_task_list = COND #( WHEN ls_order-maintenanceprocessingphase = 0  OR  ls_order-maintenanceprocessingphase = 2
                                                    THEN if_abap_behv=>fc-o-enabled
                                                    ELSE if_abap_behv=>fc-o-disabled   )
                                                    ) ).

      ENDMETHOD.

    ENDCLASS.

    CLASS lsc_c_maintorder DEFINITION INHERITING FROM cl_abap_behavior_saver.
      PROTECTED SECTION.

        METHODS check_before_save REDEFINITION.

        METHODS finalize          REDEFINITION.

        METHODS save              REDEFINITION.

    ENDCLASS.

    CLASS lsc_c_maintorder IMPLEMENTATION.

      METHOD check_before_save.
      ENDMETHOD.

      METHOD finalize.
      ENDMETHOD.

      METHOD save.

        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' DESTINATION 'NONE'.
* Begin of changes for Jet issue -   JA-9415
*          EXPORTING
*            wait = abap_true.
* End of changes.
      ENDMETHOD.

    ENDCLASS.
