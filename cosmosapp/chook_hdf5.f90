! HDF5 output for ASMC-InclinedMuon.
!
! One HDF5 table (compound dataset) is created per event:
!   /event_NNNNNNNN
! Incident-particle quantities from chookBgEvent are stored as
! attributes of that table.  Each chookObs particle is appended
! as one row.
!
! The file name is the environment variable COSMOS_H5OUT, or
! "cosmos.h5" in the working directory when that variable is unset.
! An existing file is replaced at the start of the run.

module chook_hdf5
  use hdf5
  use iso_c_binding
  use iso_fortran_env, only: error_unit
  implicit none
  private

  public :: chook_h5_open
  public :: chook_h5_add_site
  public :: chook_h5_begin_event
  public :: chook_h5_fill
  public :: chook_h5_end_event
  public :: chook_h5_close

  integer, parameter :: nobs_fields = 28
  integer, parameter :: nsite_fields = 7
  integer, parameter :: name_len = 16
  integer(hsize_t), parameter :: chunk_rows = 256_hsize_t
  integer(c_int), parameter :: gzip_level = 6_c_int

  type, bind(c) :: obs_record
    integer(c_int) :: where
    integer(c_int) :: code
    integer(c_int) :: subcode
    integer(c_int) :: charge
    integer(c_int) :: pdg
    real(c_double) :: ke_gev
    real(c_double) :: x_m
    real(c_double) :: y_m
    real(c_double) :: z_m
    real(c_double) :: px_gev
    real(c_double) :: py_gev
    real(c_double) :: pz_gev
    real(c_double) :: t
    real(c_double) :: t_ns
    integer(c_int) :: igen
    integer(c_int) :: mother_pdg
    integer(c_int) :: proj_pdg
    integer(c_int) :: mult
    real(c_double) :: mother_px
    real(c_double) :: mother_py
    real(c_double) :: mother_pz
    real(c_double) :: proj_px
    real(c_double) :: proj_py
    real(c_double) :: proj_pz
    real(c_double) :: xlab
    real(c_double) :: pt
    real(c_double) :: coll_height_m
    real(c_double) :: decay_height_m
  end type obs_record

  type, bind(c) :: site_record
    integer(c_int) :: id
    real(c_double) :: depth_g_cm2
    real(c_double) :: height_m
    real(c_double) :: radial_km
    real(c_double) :: x_m
    real(c_double) :: y_m
    real(c_double) :: z_m
  end type site_record

  interface
    function h5tbmake_table_c(title, loc_id, dset_name, nfields, nrecords, &
         type_size, field_names, field_offset, field_types, chunk_size, &
         fill_data, compress, buf) bind(c, name="H5TBmake_table") result(herr)
      import :: c_char, c_int, c_int64_t, c_ptr, c_size_t
      character(kind=c_char), intent(in) :: title(*)
      integer(c_int64_t), value :: loc_id
      character(kind=c_char), intent(in) :: dset_name(*)
      integer(c_size_t), value :: nfields
      integer(c_size_t), value :: nrecords
      integer(c_size_t), value :: type_size
      type(c_ptr), value :: field_names
      type(c_ptr), value :: field_offset
      type(c_ptr), value :: field_types
      integer(c_size_t), value :: chunk_size
      type(c_ptr), value :: fill_data
      integer(c_int), value :: compress
      type(c_ptr), value :: buf
      integer(c_int) :: herr
    end function h5tbmake_table_c

    function h5tbappend_records_c(loc_id, dset_name, nrecords, type_size, &
         field_offset, field_sizes, buf) bind(c, name="H5TBappend_records") &
         result(herr)
      import :: c_char, c_int, c_int64_t, c_ptr, c_size_t
      integer(c_int64_t), value :: loc_id
      character(kind=c_char), intent(in) :: dset_name(*)
      integer(c_size_t), value :: nrecords
      integer(c_size_t), value :: type_size
      type(c_ptr), value :: field_offset
      type(c_ptr), value :: field_sizes
      type(c_ptr), value :: buf
      integer(c_int) :: herr
    end function h5tbappend_records_c
  end interface

  integer(hid_t) :: file_id = -1
  logical :: file_is_open = .false.
  logical :: event_is_open = .false.
  logical :: sites_ready = .false.
  integer :: current_event = 0
  integer(hsize_t) :: current_nrows = 0
  character(len=32) :: current_table = ""

  integer(size_t) :: obs_type_size
  integer(size_t), target :: obs_offset(nobs_fields)
  integer(size_t), target :: obs_sizes(nobs_fields)
  integer(hid_t) :: obs_types(nobs_fields)
  character(len=name_len) :: obs_names(nobs_fields)

  integer(size_t) :: site_type_size
  integer(size_t), target :: site_offset(nsite_fields)
  integer(size_t), target :: site_sizes(nsite_fields)
  integer(hid_t) :: site_types(nsite_fields)
  character(len=name_len) :: site_names(nsite_fields)

  logical :: layout_ready = .false.

contains

  subroutine chook_h5_open(latitude, longitude, dt_gmt, year_geomag)
    real(8), intent(in) :: latitude, longitude, dt_gmt, year_geomag
    character(len=512) :: filename
    integer :: stat, err

    if (file_is_open) return

    call get_environment_variable("COSMOS_H5OUT", filename, status=stat)
    if (stat /= 0 .or. len_trim(filename) == 0) filename = "cosmos.h5"

    call h5open_f(err)
    call check("h5open", err)
    call h5fcreate_f(trim(filename), H5F_ACC_TRUNC_F, file_id, err)
    call check("h5fcreate", err)
    file_is_open = .true.
    sites_ready = .false.
    event_is_open = .false.

    call init_layout
    call put_real_id(file_id, "latitude_deg", latitude)
    call put_real_id(file_id, "longitude_deg", longitude)
    call put_real_id(file_id, "dt_gmt_hours", dt_gmt)
    call put_real_id(file_id, "year_geomag", year_geomag)
    call put_string_id(file_id, "format", "asmc-inclined-muon-v2")

    write(error_unit, "(a,a)") "HDF5 output: ", trim(filename)
    write(*, "(a,a)") "# HDF5 output: ", trim(filename)
  end subroutine chook_h5_open

  subroutine chook_h5_add_site(id, depth, height, radial_km, x, y, z)
    integer, intent(in) :: id
    real(8), intent(in) :: depth, height, radial_km, x, y, z
    type(site_record), target :: rec

    call require_open("chook_h5_add_site")
    if (.not. sites_ready) then
      call make_table("obs_sites", "observation sites", nsite_fields, &
           site_names, site_offset, site_types, site_type_size)
      call put_string("obs_sites", "units", &
           "depth:g/cm2, height:m, radial:km, x/y/z:m")
      sites_ready = .true.
    end if

    rec%id = int(id, c_int)
    rec%depth_g_cm2 = depth
    rec%height_m = height
    rec%radial_km = radial_km
    rec%x_m = x
    rec%y_m = y
    rec%z_m = z
    call append_one("obs_sites", site_type_size, site_offset, site_sizes, &
         c_loc(rec))
  end subroutine chook_h5_add_site

  subroutine chook_h5_begin_event(nevent, code, subcode, charge, pdg, &
       energy, ke, px, py, pz, coszenith, dir_x, dir_y, dir_z)
    integer, intent(in) :: nevent, code, subcode, charge, pdg
    real(8), intent(in) :: energy, ke, px, py, pz
    real(8), intent(in) :: coszenith, dir_x, dir_y, dir_z
    character(len=64) :: title

    call require_open("chook_h5_begin_event")
    if (event_is_open) call chook_h5_end_event

    current_event = nevent
    current_nrows = 0
    write(current_table, '("event_", i8.8)') nevent
    write(title, '("event ", i0)') nevent

    call make_table(trim(current_table), trim(title), nobs_fields, &
         obs_names, obs_offset, obs_types, obs_type_size)

    call put_int(current_table, "event", nevent)
    call put_int(current_table, "code", code)
    call put_int(current_table, "subcode", subcode)
    call put_int(current_table, "charge", charge)
    call put_int(current_table, "pdg", pdg)
    call put_real(current_table, "energy_gev", energy)
    call put_real(current_table, "ke_gev", ke)
    call put_real(current_table, "px_gev", px)
    call put_real(current_table, "py_gev", py)
    call put_real(current_table, "pz_gev", pz)
    call put_real(current_table, "coszenith", coszenith)
    call put_real(current_table, "dir_x", dir_x)
    call put_real(current_table, "dir_y", dir_y)
    call put_real(current_table, "dir_z", dir_z)
    call put_string(current_table, "units", &
         "header E/ke GeV, p GeV/c; rows ke GeV, xyz m, p GeV/c, " // &
         "mother/proj p GeV/c, Pt GeV/c, heights m")
    event_is_open = .true.
  end subroutine chook_h5_begin_event

  subroutine chook_h5_fill(where, code, subcode, charge, pdg, ke, &
       x, y, z, px, py, pz, t, t_ns, &
       igen, mother_pdg, proj_pdg, mult, &
       mother_px, mother_py, mother_pz, &
       proj_px, proj_py, proj_pz, xlab, pt, &
       coll_height_m, decay_height_m)
    integer, intent(in) :: where, code, subcode, charge, pdg
    integer, intent(in) :: igen, mother_pdg, proj_pdg, mult
    real(8), intent(in) :: ke, x, y, z, px, py, pz, t, t_ns
    real(8), intent(in) :: mother_px, mother_py, mother_pz
    real(8), intent(in) :: proj_px, proj_py, proj_pz
    real(8), intent(in) :: xlab, pt, coll_height_m, decay_height_m
    type(obs_record), target :: rec

    if (.not. event_is_open) then
      write(error_unit, "(a)") &
           "HDF5: chook_h5_fill called before chook_h5_begin_event"
      return
    end if

    rec%where = int(where, c_int)
    rec%code = int(code, c_int)
    rec%subcode = int(subcode, c_int)
    rec%charge = int(charge, c_int)
    rec%pdg = int(pdg, c_int)
    rec%ke_gev = ke
    rec%x_m = x
    rec%y_m = y
    rec%z_m = z
    rec%px_gev = px
    rec%py_gev = py
    rec%pz_gev = pz
    rec%t = t
    rec%t_ns = t_ns
    rec%igen = int(igen, c_int)
    rec%mother_pdg = int(mother_pdg, c_int)
    rec%proj_pdg = int(proj_pdg, c_int)
    rec%mult = int(mult, c_int)
    rec%mother_px = mother_px
    rec%mother_py = mother_py
    rec%mother_pz = mother_pz
    rec%proj_px = proj_px
    rec%proj_py = proj_py
    rec%proj_pz = proj_pz
    rec%xlab = xlab
    rec%pt = pt
    rec%coll_height_m = coll_height_m
    rec%decay_height_m = decay_height_m
    call append_one(current_table, obs_type_size, obs_offset, obs_sizes, &
         c_loc(rec))
    current_nrows = current_nrows + 1
  end subroutine chook_h5_fill

  subroutine chook_h5_end_event
    integer :: err
    if (.not. event_is_open) return
    call put_int(current_table, "nparticles", int(current_nrows))
    call h5fflush_f(file_id, H5F_SCOPE_GLOBAL_F, err)
    call check("h5fflush", err)
    event_is_open = .false.
  end subroutine chook_h5_end_event

  subroutine chook_h5_close
    integer :: err
    if (event_is_open) call chook_h5_end_event
    if (.not. file_is_open) return
    call h5fclose_f(file_id, err)
    call check("h5fclose", err)
    call h5close_f(err)
    call check("h5close", err)
    file_is_open = .false.
    file_id = -1
  end subroutine chook_h5_close

  subroutine init_layout
    type(obs_record), target :: obs
    type(site_record), target :: site
    type(c_ptr) :: obs_base, site_base

    if (layout_ready) return

    obs_names(1) = "where"
    obs_names(2) = "code"
    obs_names(3) = "subcode"
    obs_names(4) = "charge"
    obs_names(5) = "pdg"
    obs_names(6) = "ke_gev"
    obs_names(7) = "x_m"
    obs_names(8) = "y_m"
    obs_names(9) = "z_m"
    obs_names(10) = "px_gev"
    obs_names(11) = "py_gev"
    obs_names(12) = "pz_gev"
    obs_names(13) = "t"
    obs_names(14) = "t_ns"
    obs_names(15) = "igen"
    obs_names(16) = "mother_pdg"
    obs_names(17) = "proj_pdg"
    obs_names(18) = "mult"
    obs_names(19) = "mother_px"
    obs_names(20) = "mother_py"
    obs_names(21) = "mother_pz"
    obs_names(22) = "proj_px"
    obs_names(23) = "proj_py"
    obs_names(24) = "proj_pz"
    obs_names(25) = "xlab"
    obs_names(26) = "pt"
    obs_names(27) = "coll_height_m"
    obs_names(28) = "decay_height_m"
    obs_base = c_loc(obs)
    obs_offset(1) = byte_offset(obs_base, c_loc(obs%where))
    obs_offset(2) = byte_offset(obs_base, c_loc(obs%code))
    obs_offset(3) = byte_offset(obs_base, c_loc(obs%subcode))
    obs_offset(4) = byte_offset(obs_base, c_loc(obs%charge))
    obs_offset(5) = byte_offset(obs_base, c_loc(obs%pdg))
    obs_offset(6) = byte_offset(obs_base, c_loc(obs%ke_gev))
    obs_offset(7) = byte_offset(obs_base, c_loc(obs%x_m))
    obs_offset(8) = byte_offset(obs_base, c_loc(obs%y_m))
    obs_offset(9) = byte_offset(obs_base, c_loc(obs%z_m))
    obs_offset(10) = byte_offset(obs_base, c_loc(obs%px_gev))
    obs_offset(11) = byte_offset(obs_base, c_loc(obs%py_gev))
    obs_offset(12) = byte_offset(obs_base, c_loc(obs%pz_gev))
    obs_offset(13) = byte_offset(obs_base, c_loc(obs%t))
    obs_offset(14) = byte_offset(obs_base, c_loc(obs%t_ns))
    obs_offset(15) = byte_offset(obs_base, c_loc(obs%igen))
    obs_offset(16) = byte_offset(obs_base, c_loc(obs%mother_pdg))
    obs_offset(17) = byte_offset(obs_base, c_loc(obs%proj_pdg))
    obs_offset(18) = byte_offset(obs_base, c_loc(obs%mult))
    obs_offset(19) = byte_offset(obs_base, c_loc(obs%mother_px))
    obs_offset(20) = byte_offset(obs_base, c_loc(obs%mother_py))
    obs_offset(21) = byte_offset(obs_base, c_loc(obs%mother_pz))
    obs_offset(22) = byte_offset(obs_base, c_loc(obs%proj_px))
    obs_offset(23) = byte_offset(obs_base, c_loc(obs%proj_py))
    obs_offset(24) = byte_offset(obs_base, c_loc(obs%proj_pz))
    obs_offset(25) = byte_offset(obs_base, c_loc(obs%xlab))
    obs_offset(26) = byte_offset(obs_base, c_loc(obs%pt))
    obs_offset(27) = byte_offset(obs_base, c_loc(obs%coll_height_m))
    obs_offset(28) = byte_offset(obs_base, c_loc(obs%decay_height_m))
    obs_type_size = int(c_sizeof(obs), size_t)
    obs_sizes(1:5) = int(c_sizeof(obs%where), size_t)
    obs_sizes(6:14) = int(c_sizeof(obs%ke_gev), size_t)
    obs_sizes(15:18) = int(c_sizeof(obs%igen), size_t)
    obs_sizes(19:28) = int(c_sizeof(obs%mother_px), size_t)
    obs_types(1:5) = H5T_NATIVE_INTEGER
    obs_types(6:14) = H5T_NATIVE_DOUBLE
    obs_types(15:18) = H5T_NATIVE_INTEGER
    obs_types(19:28) = H5T_NATIVE_DOUBLE

    site_names = ["id         ", "depth_g_cm2", "height_m   ", &
         "radial_km  ", "x_m        ", "y_m        ", "z_m        "]
    site_base = c_loc(site)
    site_offset(1) = byte_offset(site_base, c_loc(site%id))
    site_offset(2) = byte_offset(site_base, c_loc(site%depth_g_cm2))
    site_offset(3) = byte_offset(site_base, c_loc(site%height_m))
    site_offset(4) = byte_offset(site_base, c_loc(site%radial_km))
    site_offset(5) = byte_offset(site_base, c_loc(site%x_m))
    site_offset(6) = byte_offset(site_base, c_loc(site%y_m))
    site_offset(7) = byte_offset(site_base, c_loc(site%z_m))
    site_type_size = int(c_sizeof(site), size_t)
    site_sizes(1) = int(c_sizeof(site%id), size_t)
    site_sizes(2:7) = int(c_sizeof(site%depth_g_cm2), size_t)
    site_types(1) = H5T_NATIVE_INTEGER
    site_types(2:7) = H5T_NATIVE_DOUBLE

    layout_ready = .true.
  end subroutine init_layout

  subroutine make_table(dset_name, title, nfields, names, offsets, types, &
       type_size)
    character(len=*), intent(in) :: dset_name, title
    integer, intent(in) :: nfields
    character(len=name_len), intent(in) :: names(:)
    integer(size_t), target, intent(in) :: offsets(:)
    integer(hid_t), target, intent(in) :: types(:)
    integer(size_t), intent(in) :: type_size
    character(kind=c_char), allocatable, target :: ctitle(:), cdset(:)
    character(kind=c_char), allocatable, target :: storage(:, :)
    type(c_ptr), allocatable, target :: ptrs(:)
    integer(c_int) :: herr
    integer :: i, j, n

    allocate(storage(name_len + 1, nfields), ptrs(nfields))
    storage = c_null_char
    do i = 1, nfields
      n = len_trim(names(i))
      if (n > name_len) n = name_len
      do j = 1, n
        storage(j, i) = names(i)(j:j)
      end do
      ptrs(i) = c_loc(storage(1, i))
    end do

    ctitle = to_c(title)
    cdset = to_c(dset_name)
    herr = h5tbmake_table_c(ctitle, int(file_id, c_int64_t), cdset, &
         int(nfields, c_size_t), 0_c_size_t, int(type_size, c_size_t), &
         c_loc(ptrs), c_loc(offsets), c_loc(types), &
         int(chunk_rows, c_size_t), c_null_ptr, gzip_level, c_null_ptr)
    if (herr < 0) call check("H5TBmake_table", int(herr))
  end subroutine make_table

  subroutine append_one(dset_name, type_size, offsets, sizes, buf)
    character(len=*), intent(in) :: dset_name
    integer(size_t), intent(in) :: type_size
    integer(size_t), target, intent(in) :: offsets(:), sizes(:)
    type(c_ptr), intent(in) :: buf
    character(kind=c_char), allocatable, target :: cname(:)
    integer(c_int) :: herr

    cname = to_c(dset_name)
    herr = h5tbappend_records_c(int(file_id, c_int64_t), cname, &
         1_c_size_t, int(type_size, c_size_t), c_loc(offsets), c_loc(sizes), &
         buf)
    if (herr < 0) call check("H5TBappend_records", int(herr))
  end subroutine append_one

  subroutine put_int(dset_name, attr, value)
    character(len=*), intent(in) :: dset_name, attr
    integer, intent(in) :: value
    integer(hid_t) :: dset
    integer :: err
    call h5dopen_f(file_id, dset_name, dset, err)
    call check("h5dopen", err)
    call put_int_id(dset, attr, value)
    call h5dclose_f(dset, err)
    call check("h5dclose", err)
  end subroutine put_int

  subroutine put_real(dset_name, attr, value)
    character(len=*), intent(in) :: dset_name, attr
    real(8), intent(in) :: value
    integer(hid_t) :: dset
    integer :: err
    call h5dopen_f(file_id, dset_name, dset, err)
    call check("h5dopen", err)
    call put_real_id(dset, attr, value)
    call h5dclose_f(dset, err)
    call check("h5dclose", err)
  end subroutine put_real

  subroutine put_string(dset_name, attr, value)
    character(len=*), intent(in) :: dset_name, attr, value
    integer(hid_t) :: dset
    integer :: err
    call h5dopen_f(file_id, dset_name, dset, err)
    call check("h5dopen", err)
    call put_string_id(dset, attr, value)
    call h5dclose_f(dset, err)
    call check("h5dclose", err)
  end subroutine put_string

  subroutine put_int_id(obj, attr, value)
    integer(hid_t), intent(in) :: obj
    character(len=*), intent(in) :: attr
    integer, intent(in) :: value
    integer(hsize_t) :: dims(1)
    integer(hid_t) :: space, attr_id
    integer, target :: buf(1)
    integer :: err
    dims(1) = 1
    buf(1) = value
    call h5screate_simple_f(1, dims, space, err)
    call check("h5screate", err)
    call h5acreate_f(obj, attr, H5T_NATIVE_INTEGER, space, attr_id, err)
    call check("h5acreate", err)
    call h5awrite_f(attr_id, H5T_NATIVE_INTEGER, buf, dims, err)
    call check("h5awrite", err)
    call h5aclose_f(attr_id, err)
    call h5sclose_f(space, err)
  end subroutine put_int_id

  subroutine put_real_id(obj, attr, value)
    integer(hid_t), intent(in) :: obj
    character(len=*), intent(in) :: attr
    real(8), intent(in) :: value
    integer(hsize_t) :: dims(1)
    integer(hid_t) :: space, attr_id
    real(8), target :: buf(1)
    integer :: err
    dims(1) = 1
    buf(1) = value
    call h5screate_simple_f(1, dims, space, err)
    call check("h5screate", err)
    call h5acreate_f(obj, attr, H5T_NATIVE_DOUBLE, space, attr_id, err)
    call check("h5acreate", err)
    call h5awrite_f(attr_id, H5T_NATIVE_DOUBLE, buf, dims, err)
    call check("h5awrite", err)
    call h5aclose_f(attr_id, err)
    call h5sclose_f(space, err)
  end subroutine put_real_id

  subroutine put_string_id(obj, attr, value)
    integer(hid_t), intent(in) :: obj
    character(len=*), intent(in) :: attr, value
    integer(hid_t) :: space, atype, attr_id
    integer(hsize_t) :: dims(1)
    integer(size_t) :: slen
    character(len=:), allocatable, target :: buf
    integer :: err
    if (len_trim(value) < 1) then
      buf = " "
    else
      buf = trim(value)
    end if
    slen = int(len(buf), size_t)
    dims(1) = 1
    call h5screate_f(H5S_SCALAR_F, space, err)
    call check("h5screate", err)
    call h5tcopy_f(H5T_C_S1, atype, err)
    call h5tset_size_f(atype, slen, err)
    call h5acreate_f(obj, attr, atype, space, attr_id, err)
    call check("h5acreate", err)
    call h5awrite_f(attr_id, atype, buf, dims, err)
    call check("h5awrite", err)
    call h5aclose_f(attr_id, err)
    call h5tclose_f(atype, err)
    call h5sclose_f(space, err)
  end subroutine put_string_id

  function byte_offset(base, member) result(off)
    type(c_ptr), intent(in) :: base, member
    integer(size_t) :: off
    integer(c_intptr_t) :: ibase, imember
    ibase = transfer(base, 0_c_intptr_t)
    imember = transfer(member, 0_c_intptr_t)
    off = int(imember - ibase, size_t)
  end function byte_offset

  function to_c(text) result(buf)
    character(len=*), intent(in) :: text
    character(kind=c_char), allocatable :: buf(:)
    integer :: i, n
    n = len_trim(text)
    allocate(buf(n + 1))
    do i = 1, n
      buf(i) = text(i:i)
    end do
    buf(n + 1) = c_null_char
  end function to_c

  subroutine require_open(where)
    character(len=*), intent(in) :: where
    if (.not. file_is_open) then
      write(error_unit, "(a,a)") "HDF5 file is not open in ", trim(where)
      stop 1
    end if
  end subroutine require_open

  subroutine check(label, err)
    character(len=*), intent(in) :: label
    integer, intent(in) :: err
    if (err < 0) then
      write(error_unit, "(a,a,a,i6)") "HDF5 error in ", trim(label), ": ", err
      stop 1
    end if
  end subroutine check

end module chook_hdf5
