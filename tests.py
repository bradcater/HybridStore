from hybridstore import HybridStore as HS
import unittest
from cjson import decode


class TestCoreFunctions(unittest.TestCase):
    def __init__(self,*args,**kwargs):
        super(TestCoreFunctions,self).__init__(*args,**kwargs)
        self._hs = None
        self._basic_data = [('a','1'),('b','2'),('c','3'),('d','4'),('e','5')]

    def _jd(self,s):
        try: return decode(s)
        except:
            print 'Response: %s' % s
            return False
    
    def setUp(self):
        self._hs = HS()
        self._hs.create('test')

    def tearDown(self):
        self._hs.drop('test')
        self._hs = None

    def testBasic(self):
        print 'Doing SETs...'
        for p in self._basic_data:
            r = self._hs.set(p,'test')
            json = self._jd(r)
            self.assertTrue(json)
        print 'Doing GETs...'
        for p in self._basic_data:
            r = self._hs.get(p[0],'test')
            json = self._jd(r)
            self.assertTrue(json)
            self.assertEqual(json['status'],'Ok.')
            self.assertEqual(json['response'][p[0]],p[1])
        print self._hs.info('test')


if __name__ == '__main__':
    unittest.main()
