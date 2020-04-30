class OecAddRedd < ActiveRecord::Migration
  def up
    if Oec::CourseCode.where(dept_code: 'REDD').count == 0
      Oec::CourseCode.create(
        dept_name: 'RDEV',
        catalog_id: '',
        dept_code: 'REDD',
        include_in_oec: true
      )
      Oec::CourseCode.create(
        dept_name: 'ARCH',
        catalog_id: '209',
        dept_code: 'REDD',
        include_in_oec: true
      )
      Oec::CourseCode.create(
        dept_name: 'LD ARCH',
        catalog_id: '254',
        dept_code: 'REDD',
        include_in_oec: true
      )
    end
  end

  def down
    # Downgrades should be managed through ccadmin.
  end
end
