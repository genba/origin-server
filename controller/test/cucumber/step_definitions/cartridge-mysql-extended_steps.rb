def socket_file_mysql(statement)
  cmd = ssh_command("-o LogLevel=quiet \"/usr/bin/mysql -S \\$OPENSHIFT_MYSQL_DB_SOCKET -u \\$OPENSHIFT_MYSQL_DB_USERNAME --password=\\$OPENSHIFT_MYSQL_DB_PASSWORD --batch --silent --execute='#{statement}'\"") 

  $logger.debug "Running #{cmd}"

  output = `#{cmd}`
  $logger.debug "Output: #{output}"

  output.strip
end

def app_helper_socket_file_mysql(statement)
   @app.ssh_command("-o LogLevel=quiet \"/usr/bin/mysql -S \\$OPENSHIFT_MYSQL_DB_SOCKET -u \\$OPENSHIFT_MYSQL_DB_USERNAME --password=\\$OPENSHIFT_MYSQL_DB_PASSWORD -D #{@app.name} --batch --silent --execute='#{statement}'\"")
end

Then /^I can select from the mysql database using the socket file$/ do
  socket_file_mysql('select 1').should be == "1"
end

Then /^I can select from mysql$/ do
  app_helper_socket_file_mysql('select 1').should be == '1'
end

When /^I insert (additional )?test data into mysql$/ do |additional|
  run_sql = %Q{
drop table if exists cuke_test;

create table cuke_test(
  id int not null primary key auto_increment,
  msg char(32)
);

insert into cuke_test(id, msg) values(null, \\"initial data\\");
  }

  additional_sql = %Q{
insert into cuke_test(id, msg) values(null, \\"additional data\\");
  }

  run_sql = additional_sql if additional

  app_helper_socket_file_mysql(run_sql)
end

Then /^the (additional )?test data will (not )?be present in mysql$/ do |additional, negate|
  output = app_helper_socket_file_mysql('select msg from cuke_test;')

  desired_state = !!!negate

  if (additional)
    (output.include?('additional')).should be == desired_state
  else
    (output.include?('initial')).should be == desired_state
  end
end
