from hybridstore import HybridStore as HS
import unittest
from cjson import decode


class TestCoreFunctions(unittest.TestCase):
    def __init__(self,*args,**kwargs):
        super(TestCoreFunctions,self).__init__(*args,**kwargs)
        self._hs = None
        self._basic_data = [('a','1'),('b','2'),('c','3'),('d','4'),('e','5')]
        self._numeric_data = [(1,1),(2,2),(3,3),(4,4),(5,5)]

    def _jd(self,s):
        try: return decode(s)
        except:
            print 'Response: %s' % s
            return False
    
    def _to_int(self,i):
        if not isinstance(i,int): i = int(i)
        return i

    def setUp(self):
        self._hs = HS()
        self._hs.create('test')

    def tearDown(self):
        self._hs.drop('test')
        self._hs = None

    def _test_of_data(self,lbls,data):
        self.assertEqual(len(lbls),4)
        print 'Doing %ss...' % lbls[0]
        for p in data:
            r = self._hs.set(p,'test')
            json = self._jd(r)
            self.assertTrue(json)
        print 'Doing %ss...' % lbls[1]
        for p in data:
            r = self._hs.get(p[0],'test')
            json = self._jd(r)
            self.assertTrue(json)
            self.assertEqual(json['status'],'Ok.')
            self.assertEqual(json['response'][p[0]],p[1])
        print 'DOING %ss...' % lbls[2]
        r = self._hs.get_r('b','d','test')
        json = self._jd(r)
        self.assertTrue(json)
        self.assertEqual(json['status'],'Ok.')
        for p in self._basic_data:
            if p[0] in ['b','c','d']:
                self.assertEqual(json['response'][p[0]],p[1])
        print 'DOING %ss...' % lbls[3]
        r = self._hs.info('test')
        json = self._jd(r)
        self.assertTrue(json)
        original_size = json['response']['localhost']['size']
        original_size = self._to_int(original_size)
        for i in xrange(len(data)):
            p = data[i]
            r = self._hs.dell(p[0],'test')
            json = self._jd(r)
            print json
            self.assertTrue(json)
            r = self._hs.info('test')
            json = self._jd(r)
            print json
            self.assertEqual(self._to_int(json['response']['localhost']['size']),original_size - (i + 1))

    def testBasic(self):
        self._test_of_data(('SET','GET','GET_R','DEL'),self._basic_data)

    def testNumeric(self):
        self._test_of_data(('numeric SET','numeric GET','numeric GET_R','numeric DEL'),self._numeric_data)
            

if __name__ == '__main__':
    unittest.main()
