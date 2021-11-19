@AbapCatalog.sqlViewName: '/GEN3APPS/CMNORD'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Maintenance Order'
@VDM.viewType: #CONSUMPTION
@Search.searchable: true
@Metadata.allowExtensions: true

@ObjectModel.usageType: {  
  dataClass: #MASTER,
  serviceQuality: #A,
  sizeCategory: #S
}

//******************************************************************************************************************************
// Note: This is a Consumption CDS and is created to for app - MRO Maintenance Orderdisplay filters -
// It has below additional filters inorder to navigate From App -> Maintenance Revision Detail Overview
// To App   -> MRO Enabler App 'MRO Find Maintenance Order'
// 1. Planned Start
// 2. Planned Finish
// 3. Late Completion
// 4. Actual Cost Greater than Planned Cost
// 5. Schedule Start Date Conflict
// 6. Schedule End Date Conflict
// 7. Orders without Network
//******************************************************************************************************************************
define root view /GEN3APPS/C_MaintOrder
  as select from /GEN3APPS/I_MaintOrder                           as _MnOrd

  // Join added to disable 'Do Not Execute' for Orders with Status *CRTD MEBS*
    join         /GEN3APPS/OrderStatus_TF( clnt: $session.client) as _OrdSysSt on  _OrdSysSt.Order_ID  = _MnOrd.MaintenanceOrderInternalID
                                                                               and _OrdSysSt.Stat_Lang = $session.system_language

 --Commented for unused association--
  association [0..1] to I_WBSElementBasicData         as _WBSElementBasicData        on $projection.WBSElementInternalID = _WBSElementBasicData.WBSElementInternalID

  association [0..*] to C_MaintenanceObjectStatus     as _SystemStatus               on _SystemStatus.StatusObject = $projection.MaintenanceOrderInternalID

  association [0..1] to /GEN3APPS/I_DNEOrdStat        as _DNEOrdStat                 on _DNEOrdStat.aufnr = _MnOrd.MaintenanceOrder

  association [0..1] to /GEN3APPS/CO_OrderDuration    as _MnOrdfilter                on _MnOrdfilter.MaintenanceOrder = $projection.MaintenanceOrder

  association [0..1] to /GEN3APPS/C_MaintOrderQuickVw as _MaintenanceOrderQuickVw    on _MaintenanceOrderQuickVw.MaintenanceOrder = $projection.MaintenanceOrder

  association [0..1] to /GEN3APPS/C_MaintNotifQuickVw as _MaintNotificationQuickView on $projection.MaintenanceNotification = _MaintNotificationQuickView.MaintenanceNotification

{

      @ObjectModel: { foreignKey.association: ' _MaintenanceOrderQuickVw', mandatory: true }
      @ObjectModel.text.element: [ 'MaintenanceOrderDesc' ]
  key _MnOrd.MaintenanceOrder,

      _MnOrd.MaintOrderWithLeadingZeros,

      _MnOrd.MaintenanceOrderDesc,

      _MnOrd.MaintenanceOrderInternalID,

      @ObjectModel.text.element: ['MaintenanceOrderTypeName']
      _MnOrd.MaintenanceOrderType,
      _MnOrd.MaintenanceOrderTypeName,

      _MnOrd.MaintenanceProcessingPhase,
      _MnOrd.MaintenanceProcessingPhaseDesc,

      _MnOrd.MaintPriorityType,
      @ObjectModel.text.element: ['MaintPriorityType']
      _MnOrd.MaintPriority,

      _MnOrd.MaintPriorityColorCode,
      _MnOrd.MaintPriorityDesc,

      _MnOrd.MaintenanceNotification,
      _MnOrd.MaintenanceNotificationText,

      _MnOrd.TaskListGroup,
      _MnOrd.TaskListType,
      _MnOrd.TaskListGroupCounter,
      _MnOrd.TaskListKeyDate,

      @ObjectModel.text.element: ['TaskListDesc']
      _MnOrd.TaskList,
      _MnOrd.TaskListDesc,

      _MnOrd.MaintenancePlan,
      _MnOrd.MaintenancePlanDesc,
      _MnOrd.MaintenanceItem,
      _MnOrd.MaintenanceItemDescription,

      @ObjectModel.text.element: [ 'TechnicalObjectDescription' ]
      ltrim( TechnicalObjectLabel , '0')                                  as TechnicalObjectLabel,

      _MnOrd.TechnicalObjectDescription,

      _MnOrd.TechObjIsEquipOrFuncnlLoc,
      _MnOrd.TechObjIsEquipOrFuncnlLocDesc,

      _MnOrd.OrderHasLongText,

      _MnOrd.MainWorkCenter,
      _MnOrd.MainWorkCenterText,

      _MnOrd.MaintOrdBasicStartDate,
      _MnOrd.MaintOrdBasicEndDate,
      _MnOrd.MaintOrdSchedBasicStartDate,
      _MnOrd.MaintOrdSchedBasicStartTime,

      ConcatenatedActiveUserStsName,

      @ObjectModel: {
        filter.transformedBy: 'ABAP:CL_EAM_MNTORD_STS_EXIT',
        virtualElement: true,
        virtualElementCalculatedBy: 'ABAP:CL_EAM_MNTORD_STS_EXIT'
       }
      cast(_MnOrd. ConcatenatedActiveSystStsName as abap.char(40))        as ConcatenatedActiveSystStsName,

      _MnOrd.OrderNmbrOfAttachedDocuments,

      _MnOrd.MaintOrderNumberOfOperations,

      @ObjectModel.text.element: ['MainWorkCenterPlantName']
      _MnOrd.MainWorkCenterPlant,
      _MnOrd.MainWorkCenterPlantName,

      @ObjectModel.text.element: ['MaintenancePlannerGroupName']
      _MnOrd.MaintenancePlannerGroup,
      _MnOrd.MaintenancePlannerGroupName,

      @ObjectModel.text.element: ['MaintenancePlanningPlantName']
      _MnOrd.MaintenancePlanningPlant,
      _MnOrd.MaintenancePlanningPlantName,

      _MnOrd.MaintOrdPersonResponsible, //Arushi


      @ObjectModel.virtualElement
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:CL_EAM_OBJPG_MNTORD_PART_EXIT'
      _MnOrd.PersonResponsibleName,
      _MnOrd.CreationDate,
      _MnOrd.CreatedByUser, //Arushi
      _MnOrd.CreatedByUserDescription,

      @ObjectModel.text.element: ['MaterialName']
      _MnOrd.Material,
      _MnOrd.MaterialName,

      cast(_MnOrd.SerialNumber as abap.char(18))                          as SerialNumber,

      @ObjectModel.text.element: ['AssemblyName']
      _MnOrd.Assembly,
      _MnOrd.AssemblyName,

      @ObjectModel.text.element: ['OperationSystemConditionText']
      _MnOrd.OperationSystemCondition,
      _MnOrd.OperationSystemConditionText,

      _MnOrd.MaintenanceOrderPlanningCode,
      _MnOrd.MaintOrderPlanningCodeName,

      _MnOrd.MaintenanceRevision,

      @Consumption.hidden: true
      _MnOrd.MaintenanceActivityType                                      as MaintActType,

      @ObjectModel.text.element: ['MaintenanceActivityTypeName']
      cast( case when _MnOrd.MaintenanceActivityType is null or _MnOrd.MaintenanceActivityType is initial
      then ' '   // then 'NA'    // BOG IEEA-2053
      when _MnOrd.MaintenanceActivityType = 'NA' // _MnOrd.MaintenanceActivityType = 'NA'
      then 'NA'
      else _MnOrd.MaintenanceActivityType
      end as eam_maint_activity_type preserving type )                    as MaintenanceActivityType,

      case when _MnOrd.MaintenanceActivityTypeName is null or _MnOrd.MaintenanceActivityTypeName is initial
      then 'Not Assigned'
      when _MnOrd.MaintenanceActivityType = 'NA'
      then 'Not Assigned'
      else _MnOrd.MaintenanceActivityTypeName
      end                                                                 as MaintenanceActivityTypeName,

      _MnOrd.MaintenancePlant,
      _MnOrd.PlantName,
      _MnOrd.AssetLocation,
      _MnOrd.AssetLocationName,
      _MnOrd.AssetRoom,
      _MnOrd.PlantSection,
      _MnOrd.PlantSectionPersonRespName,
      _MnOrd.PlantSectionPersonRespPhone,
      _MnOrd.WorkCenter,
      _MnOrd.WorkCenterText,
      _MnOrd.ABCIndicator,
      _MnOrd.ABCIndicatorDesc,
      _MnOrd.SortField,
      _MnOrd.CompanyCode,
      _MnOrd.CompanyCodeName,
      _MnOrd.BusinessArea,
      _MnOrd.BusinessAreaName,
      _MnOrd.ControllingArea,
      _MnOrd.ControllingAreaName,
      _MnOrd.ResponsibleCostCenter,
      _MnOrd.CostCenterName,
      _MnOrd.ProfitCenter,
      _MnOrd.ProfitCenterName,
      _MnOrd.ControllingObjectClass,
      _MnOrd.ControllingObjectClassName,
      _MnOrd.OrderProcessingGroup,
      _MnOrd.OrderProcessingGroupName,
      cast(_MnOrd.Project as abap.char(50))                               as Project,
      _MnOrd.ProjectDescription,

      cast(_MnOrd.WBSElement as abap.char(24))                            as WBSElement,
      _MnOrd.WBSDescription,

      _MnOrd.LocAcctAssgmtCompanyCode,
      _MnOrd.LocAcctAssgmtCompanyCodeName,
      _MnOrd.LocAcctAssgmtBusinessArea,
      _MnOrd.LocAcctAssgmtBusinessAreaDesc,
      _MnOrd.LocAcctAssgmtControllingArea,
      _MnOrd.LocAcctAssgmtCtrlgAreaDesc,
      _MnOrd.LocAcctAssgmtCostCenter,
      _MnOrd.LocAcctAssgmtCostCenterDesc,
      _MnOrd.CityName,
      _MnOrd.SettlementOrder,
      _MnOrd.MasterFixedAsset,
      _MnOrd.MasterFixedAssetDescription,
      _MnOrd.FixedAsset,

      cast(_MnOrd.LocAcctAssgmtWBSElement as abap.char( 24 ))             as LocAcctAssgmtWBSElement,
      _MnOrd.LocAcctAssgmtWBSElementDesc,

      _MnOrd.TechnicalObject,

      _MnOrd.AuthorizationGroup,

      cast(_MnOrd.WBSElementInternalID as abap.char( 8 ))                 as WBSElementInternalID,
      _MnOrd.Plant,


      cast(_MnOrd.MaintOrderRespPartnerFunction as abap.char(2))          as MaintOrderRespPartnerFunction,
      _MnOrd.RefTimeForOrderCompletion,

      @ObjectModel.filter.transformedBy: 'ABAP:CL_EAM_MPOVWPG_FILTER_EXIT'
      cast(_MnOrd.IsOverdue as abap.char(1))                              as IsOverdue,
      _MnOrd.MaintenanceOrderThumbnailURL,
      _MnOrd.MaintOrderIsFinallyConfirmed,

      @ObjectModel.text.element: ['StatusName']
      _MnOrd.UserStatus,
      _MnOrd.StatusName,
      _MnOrd.StatusProfile,

      _MnOrd.MaintOrderHasOpenReservations,
      _MnOrd.MaintOrdHasOpenPurchaseOrders,
      _MnOrd.MaintOrdHasOpenServices,

      @ObjectModel.virtualElement:true
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:CL_EAM_MPOVWPG_ORD_COSTS_EXIT'
      cast(_MnOrd.MaintOrdCostCriticality as abap.int1)                   as MaintOrdCostCriticality,

      @ObjectModel.virtualElement
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:CL_EAM_MPOVWPG_ORD_COSTS_EXIT'
      cast( _MnOrd.MaintOrdTotalCost as abap.sstring( 1333 ) )            as MaintOrdTotalCost,

      _MnOrd.Currency,
      _MnOrd.CompleteBusinessAndSetNotifSts,
      _MnOrd.CompleteTechlyAndSetNotifSts,
      _MnOrd.DoNotExectOrderAndSetNotifSts,
      _MnOrd.ResetTechCompltnAndSetNotifSts,
      _MnOrd.MaintObjectLocAcctAssgmtNmbr,
      _MnOrd.Equipment,
      _MnOrd.BasicSchedulingType,
      _MnOrd.OrdIsNotSchedldAutomatically,
      _MnOrd._ABCIndicator,
      _MnOrd._ActiveSystemStatus,
      _MnOrd._ActiveUserStatus,
      _MnOrd._AssetLocationVH,
      _MnOrd._BusinessArea,
      _MnOrd._CompanyCode,
      _MnOrd._CostCenter,
      _MnOrd._CreatedByUser,
      _MnOrd._EAMProductQuickVw,
      _MnOrd._Equipment,
      _MnOrd._Location,
      _MnOrd._LocationAccountAssignment,
      // _MnOrd._MaintenanceActivityType,
      @ObjectModel: { foreignKey.association: '_MaintNotificationQuickView', mandatory: true }
      _MnOrd._MaintenanceNotification,

      _MnOrd._MaintenancePlan,
      //      _MnOrd._MaintenancePlannerGroup,"bs test
      _MnOrd._MaintenancePlanningPlant,
      _MnOrd._MaintenancePlanQuickVw,
      _MnOrd._MaintenancePriority,
      _MnOrd._MaintenanceRevision,
      _MaintNotificationQuickView,
      _MnOrd._MaintOrderCost,
      _MnOrd._MaintOrderCostAggrg,
      _MnOrd._MaintOrderHasOpenReservations,
      _MnOrd._MaintOrderOperation,
      _MnOrd._MaintOrderOperationAggrg,
      _MnOrd._MaintOrderPhaseVH,
      _MnOrd._MaintOrderTypeVH,
      _MnOrd._MaintOrderWthDesc,
      _MnOrd._MaintOrdHasOpenPurchaseOrders,
      _MnOrd._MaintOrdHasOpenServices,
      _MnOrd._MaintOrdPersonResponsible,
      _MnOrd._MaintOrdPlngDegreeCode,
      _MnOrd._MaintPrioSmltdDates,
      _MnOrd._MaintTaskListQuickVw,
      _MnOrd._MainWorkCenter,
      _MnOrd._MainWorkCenterPlant,
      _MnOrd._MasterFixedAsset,
      _MnOrd._OperationSystemCondition,
      _MnOrd._OrderHasLongText,
      _MnOrd._OverdueMaintenanceOrderQ,
//      _MnOrd._PersonResponsible,"Arushi
      _MnOrd._PlantSection,
      _MnOrd._ProductionWorkCenter,
      _MnOrd._ProductionWorkCenterPlant,
      _MnOrd._SchedulingParameters,
      _MnOrd._StatusProfile,

      // @UI.selectionField: [{position: 150 }]
      _SystemStatus,
      //      _TechnicalObjectLabelVH,
      _MnOrd._TechObjIsEquipOrFuncnlLoc,
      _MnOrd._UserStatusWithStatusNumber,
      _MnOrd._UserStatusWthoutStsNmbr,
      _WBSElementBasicData,
      @Consumption.filter.hidden: true
      _MaintenanceOrderQuickVw,

      // BOC for Planned Start / End
      // Planned Start
      @ObjectModel.text.element: ['eventstatus_id']
      _MnOrdfilter.PlannedStartEvent                                      as Eventflag,

      // Planned Finish
      @ObjectModel.text.element: ['eventstatus_id']
      _MnOrdfilter.PlannedFinishEvent                                     as EventFlagFin,
      // EOC for Planned Start / End

      @ObjectModel.filter.enabled: true
      @ObjectModel.virtualElement: true
      @ObjectModel.filter.transformedBy: 'ABAP:/GEN3APPS/CL_MNT_ORD'
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:/GEN3APPS/CL_MNT_ORD'
      cast (_MnOrdfilter.LateCompletion_Flag as abap.char(3))             as LateCompletion_Flag,

      _MnOrdfilter.LateCompletion_Ind,

      _MnOrdfilter.TotalClosedOrderCount,

      _MnOrdfilter.OrderClosedOnTime,

      @ObjectModel.filter.enabled: true
      @ObjectModel.virtualElement: true
      @ObjectModel.filter.transformedBy: 'ABAP:/GEN3APPS/CL_MNT_ORD'
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:/GEN3APPS/CL_MNT_ORD'
      cast (_MnOrdfilter.ActVsPlanCost_Flag as abap.char(3))              as ActVsPlanCost_Flag,

      @Semantics.amount.currencyCode: 'Currency'
      _MnOrdfilter.ActualCost, // as Actual_Cost,
      //_OrderCost.Period02EarnedValInCtrlgArCrcy                          as ActualCost,

      @Semantics.amount.currencyCode: 'Currency'
      _MnOrdfilter.PlannedCost, // as Planned_Cost,
      //_OrderCost.Period01EarnedValInCtrlgArCrcy                          as PlannedCost,

      _MnOrdfilter.ActVsPlanCost_Ind,

      @UI.hidden: true
      cast(' ' as abap.char(30))                                          as ActionName,

      _MnOrd.LastChangeDate,
      _MnOrd.LastChangeTime,
      ///      DNEOrdStat,
      //    field for checking Order status
      _DNEOrdStat.stat                                                    as DNEOrdStat,

      //Start : For navigation from Dashbaard alert card 1, 2 and 3
      _MnOrd.ProjectNetwork,

      @Consumption.filter.hidden: true
      _MnOrd.ProjectNetworkDescription,

      //      @Consumption.valueHelpDefinition: [{ entity: { name: '/GEN3APPS/I_NETWORKACTIVITYVH',  element: 'NetworkActivity' } } ]
      @ObjectModel.text.element: ['NetworkActivityDescription']
      _MnOrd.NetworkActivity,

      @Consumption.filter.hidden: true
      _MnOrd.NetworkActivityDescription,

      _MnOrd.OrderNetworkFlag,

      @Consumption.filter.hidden: true
      _MnOrd.RvStartDateConf, // added
      @Consumption.filter.hidden: true
      _MnOrd.NwStartDateConf, // added
      @Consumption.filter.hidden: true
      _MnOrd.StartDateCriticality                                         as RvStartDateCric, // added
      @Consumption.filter.hidden: true
      _MnOrd.NwStartDateCriticality, // added

      case
            when  _MnOrd.RvStartDateConf = 'X' and _MnOrd.NwStartDateConf is null      then 'X'
            when  _MnOrd.RvStartDateConf is null and _MnOrd.NwStartDateConf = 'X'      then 'X'
            when  _MnOrd.RvStartDateConf = 'X' and _MnOrd.NwStartDateConf = 'X' then 'X'
       else ''
       end                                                                as StartDateConflict,

      case when _MnOrd.StartDateCriticality is not null and _MnOrd.NwStartDateCriticality is null     then  _MnOrd.StartDateCriticality
           when _MnOrd.StartDateCriticality is null     and _MnOrd.NwStartDateCriticality is not null then _MnOrd.NwStartDateCriticality
           when _MnOrd.StartDateCriticality is not null     and _MnOrd.NwStartDateCriticality is not null then _MnOrd.NwStartDateCriticality
      else ''
      end                                                                 as StartDateCriticality,

      @Consumption.filter.hidden: true
      _MnOrd.EndDateCriticality                                           as RvEndDateCric, //Added
      @Consumption.filter.hidden: true
      _MnOrd.RvEndDateConf, //added
      @Consumption.filter.hidden: true
      _MnOrd.NwEndDateConf,
      @Consumption.filter.hidden: true
      _MnOrd.NwEndDateCriticality,


      case when  _MnOrd.RvEndDateConf = 'X' and _MnOrd.NwEndDateConf is null  then 'X'
           when  _MnOrd.RvEndDateConf is null and _MnOrd.NwEndDateConf = 'X' then 'X'
           when  _MnOrd.RvEndDateConf = 'X' and _MnOrd.NwEndDateConf = 'X'  then 'X'
           else ''
      end                                                                 as EndDateConflict,

      @EndUserText.label: 'End Date Criticality'
      case when _MnOrd.EndDateCriticality is not null and _MnOrd.NwEndDateCriticality is null     then  _MnOrd.EndDateCriticality
           when _MnOrd.EndDateCriticality   is null     and _MnOrd.NwEndDateCriticality is not null then _MnOrd.NwEndDateCriticality
           when _MnOrd.EndDateCriticality is not null     and _MnOrd.NwEndDateCriticality is not null then _MnOrd.NwEndDateCriticality
      else ''
      end                                                                 as EndDateCriticality,


      // End : For navigation from Dashbaard alert card 1, 2 and 3

      //For navigation from Overall Status//
      ////      cast( case when _OrdOvSt.OrderDelflag = 'N'
      ////                  then ' '  else 'X' end as xfeld  )                                           as OrderDelFlag,
      cast (case _MnOrd.MaintenanceProcessingPhase
      when '4'
      then 'X'
      else ' ' end as xfeld )                                             as OrderDelFlag,

      @Consumption.filter.hidden: true
      cast( _MnOrd.FunctionalLocation as abap.char( 30 ))                 as FunctionalLocation,
      @Consumption.filter.hidden: true
      _MnOrd.EquipmentName,

      _OrdSysSt.SystemStatus                                              as OrdStat, //++Enabler 02/06/21 added to disable DNE for  MEBS ORders
      _MnOrd.MaintenanceOrderLongText
}
