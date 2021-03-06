!--------------------------------------------------------------------------------------------------!
!   CP2K: A general program to perform molecular dynamics simulations                              !
!   Copyright (C) 2000 - 2019  CP2K developers group                                               !
!--------------------------------------------------------------------------------------------------!

! **************************************************************************************************
!> \brief Types needed for MP2 calculations
!> \par History
!>       2011.05 created [Mauro Del Ben]
!> \author MDB
! **************************************************************************************************
MODULE mp2_setup
   USE cp_eri_mme_interface,            ONLY: cp_eri_mme_init_read_input
   USE cp_log_handling,                 ONLY: cp_get_default_logger,&
                                              cp_logger_type
   USE cp_output_handling,              ONLY: cp_print_key_finished_output,&
                                              cp_print_key_unit_nr
   USE input_constants,                 ONLY: do_eri_mme
   USE input_section_types,             ONLY: section_vals_get_subs_vals,&
                                              section_vals_type,&
                                              section_vals_val_get
   USE mp2_types,                       ONLY: mp2_method_direct,&
                                              mp2_method_gpw,&
                                              mp2_method_none,&
                                              mp2_ri_optimize_basis,&
                                              mp2_type,&
                                              ri_mp2_laplace,&
                                              ri_mp2_method_gpw,&
                                              ri_rpa_method_gpw
#include "./base/base_uses.f90"

   IMPLICIT NONE

   PRIVATE

   CHARACTER(len=*), PARAMETER, PRIVATE :: moduleN = 'mp2_setup'

   PUBLIC :: read_mp2_section

CONTAINS

! **************************************************************************************************
!> \brief ...
!> \param input ...
!> \param mp2_env ...
! **************************************************************************************************
   SUBROUTINE read_mp2_section(input, mp2_env)
      TYPE(section_vals_type), POINTER                   :: input
      TYPE(mp2_type), INTENT(INOUT)                      :: mp2_env

      CHARACTER(len=*), PARAMETER :: routineN = 'read_mp2_section', &
         routineP = moduleN//':'//routineN

      INTEGER                                            :: handle, ival, unit_nr
      INTEGER, DIMENSION(:), POINTER                     :: tmplist
      TYPE(cp_logger_type), POINTER                      :: logger
      TYPE(section_vals_type), POINTER                   :: eri_mme_section, mp2_section

      CALL timeset(routineN, handle)
      logger => cp_get_default_logger()

      mp2_section => section_vals_get_subs_vals(input, "DFT%XC%WF_CORRELATION")

      ! should come from input
      CALL section_vals_val_get(mp2_section, "METHOD", i_val=mp2_env%method)
      CALL section_vals_val_get(mp2_section, "MEMORY", r_val=mp2_env%mp2_memory)
      CALL section_vals_val_get(mp2_section, "SCALE_S", r_val=mp2_env%scale_S)
      CALL section_vals_val_get(mp2_section, "SCALE_T", r_val=mp2_env%scale_T)
      CALL section_vals_val_get(mp2_section, "GROUP_SIZE", i_val=mp2_env%mp2_num_proc)
      CALL section_vals_val_get(mp2_section, "DIRECT_CANONICAL%BIG_SEND", l_val=mp2_env%direct_canonical%big_send)
      CALL section_vals_val_get(mp2_section, "ROW_BLOCK", i_val=mp2_env%block_size_row)
      CALL section_vals_val_get(mp2_section, "COL_BLOCK", i_val=mp2_env%block_size_col)
      CALL section_vals_val_get(mp2_section, "RI_METRIC", i_val=mp2_env%ri_metric)
      CALL section_vals_val_get(mp2_section, "CALC_COND_NUM", l_val=mp2_env%calc_PQ_cond_num)
      CALL section_vals_val_get(mp2_section, "MINIMAL_GAP", r_val=mp2_env%minimal_gap)

      CALL section_vals_val_get(mp2_section, "INTERACTION_POTENTIAL%POTENTIAL_TYPE", &
                                i_val=mp2_env%potential_parameter%potential_type)
      CALL section_vals_val_get(mp2_section, "INTERACTION_POTENTIAL%TRUNCATION_RADIUS", &
                                r_val=mp2_env%potential_parameter%truncation_radius)
      CALL section_vals_val_get(mp2_section, "INTERACTION_POTENTIAL%TShPSC_DATA", &
                                c_val=mp2_env%potential_parameter%filename)

      CALL section_vals_val_get(mp2_section, "ERI_METHOD", &
                                i_val=mp2_env%eri_method)

      CALL section_vals_val_get(mp2_section, "WFC_GPW%EPS_FILTER", &
                                r_val=mp2_env%mp2_gpw%eps_filter)
      CALL section_vals_val_get(mp2_section, "WFC_GPW%EPS_GRID", &
                                r_val=mp2_env%mp2_gpw%eps_grid)
      CALL section_vals_val_get(mp2_section, "WFC_GPW%CUTOFF", &
                                r_val=mp2_env%mp2_gpw%cutoff)
      CALL section_vals_val_get(mp2_section, "WFC_GPW%REL_CUTOFF", &
                                r_val=mp2_env%mp2_gpw%relative_cutoff)
      CALL section_vals_val_get(mp2_section, "WFC_GPW%MULTIPOLE_TWO_CENT_INT", &
                                l_val=mp2_env%mp2_gpw%do_mult_2c)
      CALL section_vals_val_get(mp2_section, "WFC_GPW%PRINT_LEVEL", &
                                i_val=mp2_env%mp2_gpw%print_level)
      CALL section_vals_val_get(mp2_section, "WFC_GPW%EPS_PGF_ORB_S", &
                                r_val=mp2_env%mp2_gpw%eps_pgf_orb_S)
      CALL section_vals_val_get(mp2_section, "WFC_GPW%DO_CHOLESKY_SUBGROUPS", &
                                l_val=mp2_env%mp2_gpw%do_chol_subgrp)
      CALL section_vals_val_get(mp2_section, "WFC_GPW%SIZE_CHOLESKY_SUBGROUP", &
                                i_val=mp2_env%mp2_gpw%size_chol_from_input)
      CALL section_vals_val_get(mp2_section, "WFC_GPW%SIZE_LATTICE_SUM", &
                                i_val=mp2_env%mp2_gpw%size_lattice_sum)

      CALL section_vals_val_get(mp2_section, "RI_RPA%RPA_NUM_QUAD_POINTS", &
                                i_val=mp2_env%ri_rpa%rpa_num_quad_points)
      CALL section_vals_val_get(mp2_section, "RI_RPA%SIZE_FREQ_INTEG_GROUP", &
                                i_val=mp2_env%ri_rpa%rpa_integ_group_size)
      CALL section_vals_val_get(mp2_section, "RI_RPA%MM_STYLE", &
                                i_val=mp2_env%ri_rpa%mm_style)
      CALL section_vals_val_get(mp2_section, "RI_RPA%MINIMAX_QUADRATURE", &
                                l_val=mp2_env%ri_rpa%minimax_quad)
      CALL section_vals_val_get(mp2_section, "RI_RPA%ADMM", &
                                l_val=mp2_env%ri_rpa%do_admm)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0", &
                                l_val=mp2_env%ri_rpa%do_ri_g0w0)
      CALL section_vals_val_get(mp2_section, "IM_TIME", &
                                l_val=mp2_env%do_im_time)

      CALL section_vals_val_get(mp2_section, "RI_RPA%AXK", &
                                l_val=mp2_env%ri_rpa%do_ri_axk)

      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%CORR_MOS_OCC", &
                                i_val=mp2_env%ri_g0w0%corr_mos_occ)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%CORR_MOS_VIRT", &
                                i_val=mp2_env%ri_g0w0%corr_mos_virt)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%SCALING", &
                                r_val=mp2_env%ri_g0w0%scaling)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%NUMB_POLES", &
                                i_val=mp2_env%ri_g0w0%num_poles)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%NPARAM_PADE", &
                                i_val=mp2_env%ri_g0w0%nparam_pade)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%ANALYTIC_CONTINUATION", &
                                i_val=mp2_env%ri_g0w0%analytic_continuation)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%OMEGA_MAX_FIT", &
                                r_val=mp2_env%ri_g0w0%omega_max_fit)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%STOP_CRIT", &
                                r_val=mp2_env%ri_g0w0%stop_crit)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%MAX_ITER_FIT", &
                                i_val=mp2_env%ri_g0w0%max_iter_fit)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%CHECK_FIT", &
                                l_val=mp2_env%ri_g0w0%check_fit)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%CROSSING_SEARCH", &
                                i_val=mp2_env%ri_g0w0%crossing_search)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%FERMI_LEVEL_OFFSET", &
                                r_val=mp2_env%ri_g0w0%fermi_level_offset)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%EV_SC_ITER", &
                                i_val=mp2_env%ri_g0w0%iter_ev_sc)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%EPS_EV_SC_ITER", &
                                r_val=mp2_env%ri_g0w0%eps_ev_sc_iter)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%EV_SC_GW_REMOVE_NEG_VIRT_ENERGIES", &
                                l_val=mp2_env%ri_g0w0%remove_neg_virt_energies)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%HF_LIKE_EV_START", &
                                l_val=mp2_env%ri_g0w0%hf_like_ev_start)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%PRINT_GW_DETAILS", &
                                l_val=mp2_env%ri_g0w0%print_gw_details)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%RI_SIGMA_X", &
                                l_val=mp2_env%ri_g0w0%do_ri_Sigma_x)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%NORMALIZE_SIGMA", &
                                l_val=mp2_env%ri_g0w0%normalize_sigma)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%NEGLECT_NORMALIZATION_SIGMA_X", &
                                l_val=mp2_env%ri_g0w0%neglect_norm)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%RI_METRIC", &
                                i_val=mp2_env%ri_g0w0%ri_metric)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%MIX_EXCHANGE", &
                                l_val=mp2_env%ri_g0w0%mix_exchange)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%FRACTION_EXX", &
                                r_val=mp2_env%ri_g0w0%frac_exx)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%CONTOUR_DEF_START", &
                                i_val=mp2_env%ri_g0w0%contour_def_start)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%CONTOUR_DEF_END", &
                                i_val=mp2_env%ri_g0w0%contour_def_end)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%CONTOUR_DEF_OFFSET", &
                                r_val=mp2_env%ri_g0w0%contour_def_offset)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%ATOMS", &
                                i_vals=mp2_env%ri_g0w0%atoms_for_projection)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%ATOM_RANGE", &
                                i_vals=mp2_env%ri_g0w0%atom_range_for_projection)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%EPS_CHARGE", &
                                r_val=mp2_env%ri_g0w0%eps_charge)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%IC_CORR_LIST", &
                                r_vals=mp2_env%ri_g0w0%ic_corr_list)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%IC_CORR_LIST_BETA", &
                                r_vals=mp2_env%ri_g0w0%ic_corr_list_beta)

      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%BSE", &
                                l_val=mp2_env%ri_g0w0%do_bse)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%BSE%NUM_Z_VECTORS", &
                                i_val=mp2_env%ri_g0w0%num_z_vectors)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%BSE%THRESHOLD_MIN_TRANS", &
                                r_val=mp2_env%ri_g0w0%eps_min_trans)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%BSE%MAX_ITER", &
                                i_val=mp2_env%ri_g0w0%max_iter_bse)

      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%IMAGE_CHARGE_MODEL", &
                                l_val=mp2_env%ri_g0w0%do_ic_model)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%IC%PRINT_IC_LIST", &
                                l_val=mp2_env%ri_g0w0%print_ic_values)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%IC%EPS_DIST", &
                                r_val=mp2_env%ri_g0w0%eps_dist)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%IC%OPTIMIZE_HOMO_LUMO", &
                                l_val=mp2_env%ri_g0w0%do_opt_homo_lumo)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%IC%GW_EIGENVALUES", &
                                r_vals=mp2_env%ri_g0w0%gw_eigenvalues)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%IC%GW_EIGENVALUES_BETA", &
                                r_vals=mp2_env%ri_g0w0%gw_eigenvalues_beta)

      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%PERIODIC", &
                                l_val=mp2_env%ri_g0w0%do_periodic)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%PERIODIC%KPOINTS", &
                                i_vals=mp2_env%ri_g0w0%kp_grid)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%PERIODIC%NUM_KP_GRIDS", &
                                i_val=mp2_env%ri_g0w0%num_kp_grids)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%PERIODIC%EPS_KPOINT", &
                                r_val=mp2_env%ri_g0w0%eps_kpoint)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%PERIODIC%MO_COEFF_GAMMA", &
                                l_val=mp2_env%ri_g0w0%do_mo_coeff_gamma)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%PERIODIC%AVERAGE_DEGENERATE_LEVELS", &
                                l_val=mp2_env%ri_g0w0%do_average_deg_levels)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%PERIODIC%EPS_EIGENVAL", &
                                r_val=mp2_env%ri_g0w0%eps_eigenval)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%PERIODIC%EXTRAPOLATE_KPOINTS", &
                                l_val=mp2_env%ri_g0w0%do_extra_kpoints)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%PERIODIC%DO_AUX_BAS_GW", &
                                l_val=mp2_env%ri_g0w0%do_aux_bas_gw)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%PERIODIC%FRACTION_AUX_MOS", &
                                r_val=mp2_env%ri_g0w0%frac_aux_mos)
      CALL section_vals_val_get(mp2_section, "RI_RPA%RI_G0W0%PERIODIC%NUM_OMEGA_POINTS", &
                                i_val=mp2_env%ri_g0w0%num_omega_points)

      CALL section_vals_val_get(mp2_section, "IM_TIME%MEMORY_CUT", &
                                i_val=mp2_env%ri_rpa_im_time%cut_memory)
      CALL section_vals_val_get(mp2_section, "IM_TIME%MEMORY_INFO", &
                                l_val=mp2_env%ri_rpa_im_time%memory_info)
      CALL section_vals_val_get(mp2_section, "IM_TIME%MAO", &
                                l_val=mp2_env%ri_rpa_im_time%do_mao)
      CALL section_vals_val_get(mp2_section, "IM_TIME%MAO%MAO_OCC", &
                                i_vals=mp2_env%ri_rpa_im_time%nmao_occ)
      CALL section_vals_val_get(mp2_section, "IM_TIME%MAO%MAO_VIRT", &
                                i_vals=mp2_env%ri_rpa_im_time%nmao_virt)
      CALL section_vals_val_get(mp2_section, "IM_TIME%MAO%MAX_ITER_OCC", &
                                i_val=mp2_env%ri_rpa_im_time%max_iter_occ)
      CALL section_vals_val_get(mp2_section, "IM_TIME%MAO%MAX_ITER_VIRT", &
                                i_val=mp2_env%ri_rpa_im_time%max_iter_virt)
      CALL section_vals_val_get(mp2_section, "IM_TIME%MAO%EPS_GRAD_OCC", &
                                r_val=mp2_env%ri_rpa_im_time%eps_grad_occ)
      CALL section_vals_val_get(mp2_section, "IM_TIME%MAO%EPS_GRAD_VIRT", &
                                r_val=mp2_env%ri_rpa_im_time%eps_grad_virt)
      CALL section_vals_val_get(mp2_section, "IM_TIME%MAO%OPTIMIZE_SCALED_OCC_DM", &
                                l_val=mp2_env%ri_rpa_im_time%opt_sc_dm_occ)
      CALL section_vals_val_get(mp2_section, "IM_TIME%MAO%OPTIMIZE_SCALED_VIRT_DM", &
                                l_val=mp2_env%ri_rpa_im_time%opt_sc_dm_virt)
      CALL section_vals_val_get(mp2_section, "IM_TIME%GROUP_SIZE_3c", &
                                i_val=mp2_env%ri_rpa_im_time%group_size_3c)
      CALL section_vals_val_get(mp2_section, "IM_TIME%GROUP_SIZE_P", &
                                i_val=mp2_env%ri_rpa_im_time%group_size_P)
      CALL section_vals_val_get(mp2_section, "IM_TIME%POINTS_PER_MAGNITUDE", &
                                i_val=mp2_env%ri_rpa_im_time%num_points_per_magnitude)
      CALL section_vals_val_get(mp2_section, "IM_TIME%EPS_FILTER_IM_TIME", &
                                r_val=mp2_env%ri_rpa_im_time%eps_filter_im_time)
      CALL section_vals_val_get(mp2_section, "IM_TIME%STABILIZE_EXP", &
                                r_val=mp2_env%ri_rpa_im_time%stabilize_exp)
      CALL section_vals_val_get(mp2_section, "IM_TIME%DO_KPOINTS", &
                                l_val=mp2_env%ri_rpa_im_time%do_im_time_kpoints)

      CALL section_vals_val_get(mp2_section, "IM_TIME%RI_G0W0", &
                                l_val=mp2_env%ri_rpa_im_time%do_gw_im_time)

      CALL section_vals_val_get(mp2_section, "RI_LAPLACE%QUADRATURE_POINTS", &
                                i_val=mp2_env%ri_laplace%n_quadrature)
      CALL section_vals_val_get(mp2_section, "RI_LAPLACE%SIZE_INTEG_GROUP", &
                                i_val=mp2_env%ri_laplace%integ_group_size)

      CALL section_vals_val_get(mp2_section, "RI_MP2%BLOCK_SIZE", &
                                i_val=mp2_env%ri_mp2%block_size)
      CALL section_vals_val_get(mp2_section, "RI_MP2%EPS_CANONICAL", &
                                r_val=mp2_env%ri_mp2%eps_canonical)
      CALL section_vals_val_get(mp2_section, "RI_MP2%FREE_HFX_BUFFER", &
                                l_val=mp2_env%ri_mp2%free_hfx_buffer)

      CALL section_vals_val_get(mp2_section, "CPHF%MAX_ITER", &
                                i_val=mp2_env%ri_grad%cphf_max_num_iter)
      CALL section_vals_val_get(mp2_section, "CPHF%EPS_CONV", &
                                r_val=mp2_env%ri_grad%cphf_eps_conv)

      CALL section_vals_val_get(mp2_section, "OPT_RI_BASIS%DELTA_I_REL", &
                                r_val=mp2_env%ri_opt_param%DI_rel)
      CALL section_vals_val_get(mp2_section, "OPT_RI_BASIS%DELTA_RI", &
                                r_val=mp2_env%ri_opt_param%DRI)
      CALL section_vals_val_get(mp2_section, "OPT_RI_BASIS%EPS_DERIV", &
                                r_val=mp2_env%ri_opt_param%eps_step)
      CALL section_vals_val_get(mp2_section, "OPT_RI_BASIS%MAX_ITER", &
                                i_val=mp2_env%ri_opt_param%max_num_iter)
      CALL section_vals_val_get(mp2_section, "OPT_RI_BASIS%BASIS_SIZE", &
                                i_val=mp2_env%ri_opt_param%basis_quality)
      NULLIFY (tmplist)
      CALL section_vals_val_get(mp2_section, "OPT_RI_BASIS%NUM_FUNC", &
                                i_vals=tmplist)
      IF (tmplist(1) > 0) THEN
         ALLOCATE (mp2_env%ri_opt_param%RI_nset_per_l(0:SIZE(tmplist)-1))
         mp2_env%ri_opt_param%RI_nset_per_l = 0
         DO ival = 1, SIZE(tmplist)
            mp2_env%ri_opt_param%RI_nset_per_l(ival-1) = tmplist(ival)
         END DO
      END IF

      NULLIFY (mp2_env%eri_mme_param)
      ALLOCATE (mp2_env%eri_mme_param)

      IF (mp2_env%eri_method .EQ. do_eri_mme) THEN
         eri_mme_section => section_vals_get_subs_vals(mp2_section, "ERI_MME")
         CALL cp_eri_mme_init_read_input(eri_mme_section, mp2_env%eri_mme_param)
      ENDIF
      CALL section_vals_val_get(mp2_section, "ERI_BLKSIZE", i_vals=mp2_env%eri_blksize)

      ! Set some parameters in case of P screening
      mp2_env%not_last_hfx = .TRUE.
      mp2_env%p_screen = .TRUE.

      ! print some info about the MP2 parameters
      unit_nr = cp_print_key_unit_nr(logger, mp2_section, "MP2_INFO", &
                                     extension=".mp2Log")
      IF ((mp2_env%method .NE. mp2_method_none) .AND. unit_nr > 0) THEN
         WRITE (unit_nr, '(T2,A)') ""
         SELECT CASE (mp2_env%method)
         CASE (mp2_method_direct)
            WRITE (unit_nr, '(T2,A)') "MP2| using direct canonical MP2"
         CASE (mp2_method_gpw)
            WRITE (unit_nr, '(T2,A)') "MP2| using MP2 GPW style"
         CASE (ri_mp2_method_gpw)
            WRITE (unit_nr, '(T2,A)') "MP2| using RI-MP2-GPW"
         CASE (ri_rpa_method_gpw)
            WRITE (unit_nr, '(T2,A)') "RI-RPA| using GPW style"
         CASE (ri_mp2_laplace)
            WRITE (unit_nr, '(T2,A)') "RI-SOS-Laplace-MP2| using GPW style"
         CASE (mp2_ri_optimize_basis)
            WRITE (unit_nr, '(T2,A)') "MP2| Optimize RI auxiliary basis"
         CASE DEFAULT
            CPABORT("")
         END SELECT
         WRITE (unit_nr, '(T2,A)') ""
      ENDIF
      CALL cp_print_key_finished_output(unit_nr, logger, mp2_section, &
                                        "MP2_INFO")

      CALL timestop(handle)

   END SUBROUTINE read_mp2_section

END MODULE mp2_setup

