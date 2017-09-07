@App.controller 'InvoiceController', ($stateParams, $uibModal, $window, $state, toastr, MnoeAdminConfig, MnoeInvoices, DatesHelper, MnoConfirm) ->
  'ngInject'
  vm = this

  # -----------------------------------------------------------------
  # Initialize
  # -----------------------------------------------------------------
  vm.isPaymentEnabled = MnoeAdminConfig.isPaymentEnabled()
  vm.isLoading = true
  vm.invoice = {}

  MnoeInvoices.get($stateParams.invoiceId).then(
    (response) ->
      vm.invoice = response.data.plain().invoice
      vm.isInvoiceEditedPaid = angular.copy(vm.invoice.paid_at)
      vm.invoice.adjustments = [] unless vm.invoice.adjustments?
  ).finally(-> vm.isLoading = false)

  # -----------------------------------------------------------------
  # Invoice Management
  # -----------------------------------------------------------------
  vm.downloadInvoice = (slug, event) ->
    $window.open('/mnoe/admin/invoices/' + slug, '_blank')
    # avoid change to single invoice view when click in this cell
    event.stopPropagation()

  # The expected date is the 2nd of the month following the invoice period
  vm.expectedPaymentDate = (endOfInvoiceDate) ->
    DatesHelper.expectedPaymentDate(endOfInvoiceDate)

  vm.changeInvoiceStatus = () ->
    vm.invoice.paid_at = moment().toISOString()

  vm.update = () ->
    vm.isLoading = true
    MnoeInvoices.update(vm.invoice).then(
      ->
        toastr.success('mnoe_admin_panel.dashboard.invoice.details.updated')
    ).finally(-> vm.isLoading = false)
    $state.go('dashboard.invoices')

  # -----------------------------------------------------------------
  #  Adjustment Management
  # -----------------------------------------------------------------
  vm.openAddAdjustmentModal = () ->
    modalInstance = $uibModal.open(
      templateUrl: 'app/views/invoices/modals/adjustment-modal.html'
      controller: 'CreateAdjustmentController'
      controllerAs: 'vm'
    )
    modalInstance.result.then(
      (adjustment) ->
        # Add the adjustment adjustment
        vm.invoice.adjustments.push(adjustment)
    )

  vm.openEditAdjustmentModal = (adjustment) ->
    vm.oldAdjustment = angular.copy(adjustment)
    modalInstance = $uibModal.open(
      templateUrl: 'app/views/invoices/modals/adjustment-modal.html'
      controller: 'EditAdjustmentController'
      controllerAs: 'vm'
      resolve:
        adjustment: vm.oldAdjustment
    )
    modalInstance.result.then(
      (adjustmentEdited) ->
        # If the adjustment is modified
        if adjustmentEdited
          indexOfAdjustment = vm.invoice.adjustments.indexOf(adjustment)
          vm.invoice.adjustments.splice(indexOfAdjustment, 1)
          vm.invoice.adjustments.push(adjustmentEdited)
    )

  vm.openDeleteAdjustmentModal = (adjustment) ->
    modalOptions =
      headerText: 'mnoe_admin_panel.dashboard.invoice.delete_adjustments.are_you_sure'
      bodyText: 'mnoe_admin_panel.dashboard.invoice.delete_adjustments.you_will_not'
      closeButtonText: 'mnoe_admin_panel.dashboard.invoice.delete_adjustments.cancel'
      actionButtonText: 'mnoe_admin_panel.dashboard.invoice.delete_adjustments.delete'
      type: 'danger'

    MnoConfirm.showModal(modalOptions).then(
      ->
        # If user delete the adjustment
        indexOfAdjustment = vm.invoice.adjustments.indexOf(adjustment)
        vm.invoice.adjustments.splice(indexOfAdjustment, 1)
    )

  return
