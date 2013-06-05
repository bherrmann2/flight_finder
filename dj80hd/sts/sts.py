import subprocess
import os

class SelfTestingScriptException(Exception):
  pass

def assert_cmd_exists(cmd):
  should_not_find = "no " + cmd
  try:
    which_output = get_cmd_output("which " + cmd)
    if should_not_find in which_output:
      raise SelfTestingScriptException("Command " + cmd + " does not exit.")
  except subprocess.CalledProcessError as e:
      raise SelfTestingScriptException("Command " + cmd + " does not exit.")
      
def assert_process_exists(process_name):
    ps_output = get_cmd_output("ps aux")
    if process_name not in ps_output:
      raise SelfTestingScriptException("Could not find process " + process_name)
    
def get_cmd_output(cmd):
    try:
        out = subprocess.check_output(cmd,stderr=subprocess.STDOUT,shell=True)
        return out
    except subprocess.CalledProcessError as e:
        return ""

def assert_env_exists(env_var):
    if not (env_var in os.environ): 
        raise SelfTestingScriptException("Could not find env var " + env_var)

def assert_env_equal(env_var,value):
    assert_env_exists(env_var)
    val = os.environ[env_var]
    if not (val == value):
        raise SelfTestingScriptException("env var " + env_var + " is " + str(val) + " not " + value)
     

def assert_exits(file_or_dir):
  pass

def assert_readable(file_or_dir):
  pass

def assert_writeable(file_or_dir):
  pass


#assert_cmd_exists("ffmpeg")
#assert_process_exists("sendmail")
#assert_process_exists("xsendmail")
assert_env_equal('FOO','BAR')
os.environ['FOO2'] = 'gotit'
print get_cmd_output("env|grep FOO")
##################################################



