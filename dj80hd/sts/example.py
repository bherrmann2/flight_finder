import StsStep from sts


class AddHostStep(StsStep):
    def __init__(self,host):
        self.host = host
        self.hostfile = "/home/werwath/.ssh"
    def assert_preconditions(self):
        assert_user('werwath')
    def is_complete(self):


