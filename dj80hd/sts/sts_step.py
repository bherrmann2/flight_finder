import sts

class StsStep():

    def assert_complete(self):
        if not self.is_complete()
            raise SelfTestingScriptException("Incomplete Step")
    def is_complete(self):
        return True
    def assert_preconditions(self):
        pass
    def execute(self):
        pass
    def backout(self):
        pass
