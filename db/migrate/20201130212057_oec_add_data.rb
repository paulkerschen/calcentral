class OecAddData < ActiveRecord::Migration[6.0]
  def up
    if Oec::CourseCode.where(dept_code: 'DSDIV').count == 0
      Oec::CourseCode.create(
        dept_name: 'DATA',
        catalog_id: '',
        dept_code: 'DSDIV',
        include_in_oec: true
      )
    end
  end

  def down
    # Downgrades should be handled manually.
  end
end
