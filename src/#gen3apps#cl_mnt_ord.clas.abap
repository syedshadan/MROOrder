class /GEN3APPS/CL_MNT_ORD definition
  public
  final
  create public .

public section.

  interfaces IF_SADL_EXIT_FILTER_TRANSFORM .
  interfaces IF_SADL_EXIT .
  interfaces IF_SADL_EXIT_CALC_ELEMENT_READ .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS /GEN3APPS/CL_MNT_ORD IMPLEMENTATION.


         METHOD if_sadl_exit_calc_element_read~calculate .

           DATA : lt_calculated_data      TYPE STANDARD TABLE OF /gen3apps/co_orderduration.
           DATA : lt_calculated_data_oper TYPE STANDARD TABLE OF /gen3apps/co_operefforts.
           DATA : lt_calculated_data_CMaint TYPE STANDARD TABLE OF /gen3apps/c_maintorder.


           MOVE-CORRESPONDING it_original_data TO lt_calculated_data .
           MOVE-CORRESPONDING it_original_data TO lt_calculated_data_oper .

           LOOP AT lt_calculated_data ASSIGNING FIELD-SYMBOL(<fs_data>) WHERE latecompletion_ind IS NOT INITIAL .
             <fs_data>-latecompletion_flag =
                COND #( WHEN <fs_data>-totalclosedordercount = 1 AND <fs_data>-orderclosedontime = 1
                          THEN 'No'
                        WHEN <fs_data>-totalclosedordercount = 1 AND <fs_data>-orderclosedontime = 0
                          THEN 'Yes'
                        WHEN <fs_data>-totalclosedordercount = 0 AND <fs_data>-orderclosedontime = 0
                          THEN 'Yes'
                      ).
           ENDLOOP.

           LOOP AT lt_calculated_data ASSIGNING FIELD-SYMBOL(<fs_data1>) WHERE actvsplancost_ind IS NOT INITIAL.
             <fs_data1>-actvsplancost_flag =                                   "
                COND #( WHEN <fs_data1>-actualcost > <fs_data1>-plannedcost
                         THEN 'Yes'
                         ELSE 'No'
                      ).
           ENDLOOP.

           LOOP AT lt_calculated_data_oper ASSIGNING FIELD-SYMBOL(<fs_data2>) WHERE effortind is NOT INITIAL.
             <fs_data2>-forplaneff_indicator =
                COND #( WHEN <fs_data2>-forecast <= <fs_data2>-plannedwork   " mroforecastwork
                   THEN 'No'
                   ELSE 'Yes' ).
           ENDLOOP.

           MOVE-CORRESPONDING lt_calculated_data TO  ct_calculated_data.
           MOVE-CORRESPONDING lt_calculated_data_oper TO ct_calculated_data.

         ENDMETHOD.


        METHOD if_sadl_exit_calc_element_read~get_calculation_info.

          IF line_exists( it_requested_calc_elements[ table_line = 'ACTVSPLANCOST_FLAG' ] ).
*          APPEND 'ACTUALCOST' TO et_requested_orig_elements.
            INSERT |ACTUALCOST| INTO TABLE et_requested_orig_elements.
            INSERT |ACTVSPLANCOST_IND| INTO TABLE et_requested_orig_elements .
            INSERT |PLANNEDCOST| INTO TABLE et_requested_orig_elements .
          ENDIF.

          IF line_exists( it_requested_calc_elements[ table_line = 'LATECOMPLETION_FLAG' ] ).
            INSERT |ORDERCLOSEDONTIME| INTO TABLE et_requested_orig_elements .
            INSERT |TOTALCLOSEDORDERCOUNT| INTO TABLE et_requested_orig_elements.
            INSERT |LATECOMPLETION_IND| INTO TABLE et_requested_orig_elements.
          ENDIF.

          IF line_exists( it_requested_calc_elements[ table_line = 'FORPLANEFF_INDICATOR' ] ).
            INSERT |EFFORTIND| INTO TABLE et_requested_orig_elements .
            INSERT |FORECAST| INTO TABLE et_requested_orig_elements.
            INSERT |PLANNEDWORK| INTO TABLE et_requested_orig_elements .
            INSERT |RELCOUNT|  INTO TABLE et_requested_orig_elements .
          ENDIF.

        ENDMETHOD.


        METHOD if_sadl_exit_filter_transform~map_atom.

          DATA(lo_cfac) = cl_sadl_cond_prov_factory_pub=>create_simple_cond_factory( ).

**** For Late Completion
          IF iv_element = 'LATECOMPLETION_FLAG'.
            DATA(latcomp) = lo_cfac->element( 'LATECOMPLETION_IND' ).
            DATA(lv_latecomp_val) = iv_value.

            IF iv_value CP 'tru'.
              lv_latecomp_val = 'Yes'.
            ELSEIF iv_value CP 'fal'.
              lv_latecomp_val = 'No'.
            ENDIF.

            CASE iv_operator.
              WHEN if_sadl_exit_filter_transform~co_operator-equals.
                ro_condition = latcomp->equals( lv_latecomp_val ) .

              WHEN if_sadl_exit_filter_transform~co_operator-is_null.
                ro_condition = latcomp->is_null( ).
            ENDCASE.
          ENDIF.

**** For Actual Cost > Planned Cost
          IF iv_element = 'ACTVSPLANCOST_FLAG'.
            DATA(actplancost) = lo_cfac->element( 'ACTVSPLANCOST_IND' ).
            DATA(lv_acplcost_val) = iv_value.

            IF iv_value CP 'tru'.
              lv_acplcost_val = 'Yes'.
            ELSEIF iv_value CP 'fal'.
              lv_acplcost_val = 'No'.
            ENDIF.

            CASE iv_operator.
              WHEN if_sadl_exit_filter_transform~co_operator-equals.
                ro_condition = actplancost->equals( lv_acplcost_val ) .

              WHEN if_sadl_exit_filter_transform~co_operator-is_null.
                ro_condition = actplancost->is_null( ).
            ENDCASE.
          ENDIF.

**** For Forecast Effort > Planned Effort
          IF iv_element = 'FORPLANEFF_INDICATOR'.
            DATA(effort) = lo_cfac->element( 'EFFORTIND' ).
            DATA(lv_effort_flag) = iv_value.

            IF iv_value CP 'tru'.
              lv_effort_flag = 'Yes'.
            ELSEIF iv_value CP 'fal'.
              lv_effort_flag = 'No'.
            ENDIF.

            CASE iv_operator.
              WHEN if_sadl_exit_filter_transform~co_operator-equals.
                ro_condition = effort->equals( lv_effort_flag ) .

              WHEN if_sadl_exit_filter_transform~co_operator-is_null.
                ro_condition = effort->is_null( ).
            ENDCASE.
          ENDIF.

***** For handling Not Assigned Maintenance Activity Type Name
*          IF iv_element = 'MAINTENANCEACTIVITYTYPENAME'.
*            DATA(mntacttype) = lo_cfac->element( 'MAINTENANCEACTIVITYTYPENAME' ).
*            DATA(lv_value) = iv_value.
*
*            DATA(lv_operator) = iv_operator.
*            IF iv_value EQ 'Not Assigned'.
*              lv_operator = if_sadl_exit_filter_transform~co_operator-is_null .
*            ENDIF.
*
*            CASE lv_operator.
*              WHEN if_sadl_exit_filter_transform~co_operator-equals.
*                ro_condition = mntacttype->equals( lv_value ) .
*
*              WHEN if_sadl_exit_filter_transform~co_operator-is_null.
*                ro_condition = mntacttype->is_null( ).
*            ENDCASE.
*          ENDIF.

        ENDMETHOD.
ENDCLASS.
