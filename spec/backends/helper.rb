module BackendsHelper
  TEST_DATA_ROWS_SQL = 1500
  TEST_DATA_INSERT_SLICE_SQL = 200
  
  def random_values()
    values = []
    id = 0
    TEST_DATA_ROWS_SQL.times {
      value = rand(2**16)
      values << "(#{id},#{value},'#{value.to_s}')"
    }
    return values
  end

  def drop_test()
    sql = "DROP TABLE IF EXISTS tmp"
    @server.query(sql)
  end

  def populate_test()
    drop_test()
    sql = "CREATE TABLE tmp (
        id INT(10) NOT NULL AUTO_INCREMENT,
        num INT(10) NOT NULL,
        str TEXT NOT NULL,
        PRIMARY KEY (id)
        )"
    @server.query(sql)

    random_values().each_slice(TEST_DATA_INSERT_SLICE_SQL) {|slice|
      sql = "INSERT INTO tmp (id,num,str) VALUES " + slice.join(",")
      result = @server.query(sql)
      result.affected_rows()
    }
  end
end