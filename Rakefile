require 'rake'
require 'rspec/core/rake_task'
require 'yaml'

# param: none
# return: @playbook, @inventoryfile
def load_ansiblespec()
  f = '.ansiblespec'
  if File.exist?(f)
    y = YAML.load_file(f)
    @playbook = y['playbook']
    @inventoryfile = y['inventory']
  else
    @playbook = 'site.yml'
    @inventoryfile = 'hosts'
  end
  if File.exist?(@playbook) == false
    puts 'Error: ' + @playbook + ' is not Found. create site.yml or /.ansiblespec  See https://github.com/volanja/ansible_spec'
    exit 1
  elsif File.exist?(@inventoryfile) == false
    puts 'Error: ' + @inventoryfile + ' is not Found. create hosts or /.ansiblespec  See https://github.com/volanja/ansible_spec'
    exit 1
  end
end

# param: inventory file of Ansible
# return: Hash {"active_group_name" => ["192.168.0.1","192.168.0.2"]}
def load_host(file)
  hosts = File.open(file).read
  active_group = Hash.new
  active_group_name = ''
  hosts.each_line{|line|
    line = line.chomp
    next if line.start_with?('#')
    if line.start_with?('[') && line.end_with?(']')
      active_group_name = line.gsub('[','').gsub(']','')
      active_group["#{active_group_name}"] = Array.new
    elsif active_group_name.empty? == false
      next if line.empty? == true
      active_group["#{active_group_name}"] << line
    end
  }
  return active_group
end

# main
load_ansiblespec
load_file = YAML.load_file(@playbook)

# e.g. comment-out
if load_file === false
  puts 'Error: No data in site.yml'
  exit
end

properties = Array.new
load_file.each do |site|
  if site.has_key?("include")
    properties.push YAML.load_file(site["include"])[0]
  else
    properties.push site
  end
end

#load inventory file
hosts = load_host(@inventoryfile)

# fake out host group 'all'
all_hosts = []
hosts.each do |name, host|
  all_hosts += host
end
hosts['all'] = all_hosts.uniq

#puts hosts.inspect
puts "testing #{@playbook} against hosts found in #{@inventoryfile}"
#puts "properties: #{properties.inspect}"
properties.each do |var|
  var["name"] = var["name"].gsub(" ", "_")
  var["hostlist"] = []
  hostlist = var["hosts"].split(":").each do |derp|
    var["hostlist"] += hosts[derp] if hosts.has_key?(derp)
      #puts "hosts: #{var["hosts"]}"
  end
  # make array of roles
  var["role_list"] = []
  if var["roles"].kind_of?(Array)
    var["roles"].each do |role|
      var["role_list"] += [role["role"]]
    end
  end
end

# compile list of tasks for spec:all
tasks = []
properties.each do |prop|
  prop["hostlist"].each do |host|
    tasks += ["spec:#{prop['name']}:#{host}"]
  end
end

task :spec => 'spec:all'

namespace :spec do
  task :all => tasks
  properties.each do |prop|
    prop["hostlist"].each do |host|
      desc "Run serverspec to #{host}"
      RSpec::Core::RakeTask.new("#{prop['name']}:#{host}") do |t|
        puts "running tasks - spec:#{prop['name']}:#{host}"
        ENV['TARGET_HOST'] = host
        ENV['TARGET_PRIVATE_KEY'] = 'envs/test/int-test.pem'
        ENV['TARGET_USER'] = 'root'
        t.pattern = 'roles/{' + prop["role_list"].join(",") + '}/tests/serverspec/*_spec.rb'
      end
    end
  end
end
