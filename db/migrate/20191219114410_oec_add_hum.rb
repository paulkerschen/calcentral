class OecAddHum < ActiveRecord::Migration
  def up
    if Oec::CourseCode.where(dept_code: 'LS1HU').count == 0
      Oec::CourseCode.create(
        dept_name: 'HUM',
        catalog_id: '',
        dept_code: 'LS1HU',
        include_in_oec: true
      )
    end
  end

  def down
    # Downgrades should be managed through ccadmin.
  end
end
