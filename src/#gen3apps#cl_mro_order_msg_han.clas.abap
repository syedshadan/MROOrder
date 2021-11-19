class /GEN3APPS/CL_MRO_ORDER_MSG_HAN definition
  public
  inheriting from CL_ABAP_BEHV
  final
  create public .

public section.
  class CL_ABAP_BEHV definition load .

  types:
    TT_ENAB_FAILED   TYPE TABLE FOR FAILED   /GEN3APPS/C_MAINTORDER .
  types:
    TT_ENAB_MAPPED   TYPE TABLE FOR MAPPED   /GEN3APPS/C_MAINTORDER .
  types:
    TT_ENAB_REPORTED TYPE TABLE FOR REPORTED /GEN3APPS/C_MAINTORDER .

  class-methods HANDLE_MESSAGES
    importing
      !IT_MESSAGES type STTY_MESSAGE optional
    changing
      !FAILED type TT_ENAB_FAILED optional
      !MAPPED type TT_ENAB_MAPPED optional
      !REPORTED type TT_ENAB_REPORTED optional .
protected section.
private section.

  class-data OBJ type ref to /GEN3APPS/CL_MRO_ORDER_MSG_HAN .

  class-methods GET_MESSAGE_OBJECT
    returning
      value(R_RESULT) type ref to /GEN3APPS/CL_MRO_ORDER_MSG_HAN .
ENDCLASS.



CLASS /GEN3APPS/CL_MRO_ORDER_MSG_HAN IMPLEMENTATION.


  method GET_MESSAGE_OBJECT.
    IF obj IS INITIAL.
      CREATE OBJECT obj.
    ENDIF.
    r_result = obj.
  endmethod.


  method HANDLE_MESSAGES.


 LOOP AT it_messages INTO DATA(ls_message).
      IF ls_message-type = 'S' or ls_message-type = 'I'.
        APPEND VALUE #(  maintenanceorder = space ) TO mapped .

        APPEND VALUE #( %msg = get_message_object( )->new_message( id = ls_message-id
        number = ls_message-number
        severity = if_abap_behv_message=>severity-success
        v1 = ls_message-MESSAGE_v1
        v2 = ls_message-MESSAGE_v2
        v3 = ls_message-MESSAGE_v3
        v4 = ls_message-MESSAGE_v4 )

          %key-maintenanceorder = space
          maintenanceorder = space ) TO reported.

      ELSEIF ls_message-type = 'W'.
        APPEND VALUE #(  maintenanceorder = space ) TO mapped .

        APPEND VALUE #( %msg = get_message_object( )->new_message( id = ls_message-id
        number = ls_message-number
        severity = if_abap_behv_message=>severity-warning
        v1 = ls_message-MESSAGE_v1
        v2 = ls_message-MESSAGE_v2
        v3 = ls_message-MESSAGE_v3
        v4 = ls_message-MESSAGE_v4 )

          %key-maintenanceorder = space
          maintenanceorder = space ) TO reported.

      ELSEIF ls_message-type = 'E'.
        APPEND VALUE #(   maintenanceorder = space ) TO failed .

        APPEND VALUE #( %msg = get_message_object( )->new_message( id = ls_message-id
        number = ls_message-number
        severity = if_abap_behv_message=>severity-error
        v1 = ls_message-MESSAGE_v1
        v2 = ls_message-MESSAGE_v2
        v3 = ls_message-MESSAGE_v3
        v4 = ls_message-MESSAGE_v4 )

          %key-maintenanceorder = space
          maintenanceorder = space ) TO reported.
      ENDIF.
    ENDLOOP.


  endmethod.
ENDCLASS.
