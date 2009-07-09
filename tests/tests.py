from hybridstore import HybridStore as HS
import unittest
from cjson import DecodeError, decode


def to_dict(a):
    # transform, e.g., [('key','value'),...] to {'key':'value'}
    d = {}
    for p in a: d[p[0]] = p[1]
    return d


class HybridStoreTestBase(unittest.TestCase):
    def __init__(self,*args,**kwargs):
        super(HybridStoreTestBase,self).__init__(*args,**kwargs)
        self._hs = HS()
        self._all_data = [('tom','male'),('angie','female'),('marshall','male'),('debbie','female'),('orson','male'),('jenny','female')]
        self._basic_data = [('a','1'),('b','2'),('c','3'),('d','4'),('e','5')]
        self._numeric_data = [(1,1),(2,2),(3,3),(4,4),(5,5)]

    def _assert_get(self,key,val,tree):
        json = self._hs.get(key,tree)
        self._json_ok(json)
        self.assertEqual(json.get('response',{}).get(key),val)

    def _json_error(self,json):
        self.assertTrue(json)
        self.assertEqual(json.get('status'),'Failure.')

    def _json_ok(self,json):
        self.assertTrue(json)
        self.assertEqual(json.get('status'),'Ok.')

    def setUp(self):
        self._hs.create('test')

    def tearDown(self):
        self._hs.drop('test')


class TestCore(HybridStoreTestBase):
    def _to_int(self,i):
        if not isinstance(i,int): i = int(i)
        return i

    def _test_of_data(self,lbls,data):
        self.assertEqual(len(lbls),4)
        print 'Doing %ss...' % lbls[0]
        for p in data:
            json = self._hs.set(p,'test')
            self.assertTrue(json)
        print 'Doing %ss...' % lbls[1]
        for p in data:
            json = self._hs.get(p[0],'test')
            self._json_ok(json)
            self.assertEqual(json['response'][p[0]],p[1])
        print 'DOING %ss...' % lbls[2]
        json = self._hs.get_r('b','d','test')
        self._json_ok(json)
        for p in data:
            if p[0] in ['b','c','d']:
                self.assertEqual(json['response'][p[0]],p[1])
        print 'DOING %ss...' % lbls[3]
        json = self._hs.info('test')
        self.assertTrue(json)
        original_size = json['response']['localhost']['size']
        original_size = self._to_int(original_size)
        for i in xrange(len(data)):
            p = data[i]
            json = self._hs.dell(p[0],'test')
            self._json_ok(json)
            json = self._hs.info('test')
            self._json_ok(json)
            self.assertEqual(self._to_int(json['response']['localhost']['size']),original_size - (i + 1))

    def testAll(self):
        print 'Doing SETs...'
        for p in self._all_data:
            json = self._hs.set(p,'test')
            self._json_ok(json)
        print 'Doing ALL...'
        json = self._hs.all('test')
        self._json_ok(json)
        d = json.get('response')
        data_d = to_dict(self._all_data)
        for k,v in d.items():
            self.assertEqual(v,data_d.get(k))
    
    def testBasic(self):
        self._test_of_data(('SET','GET','GET_R','DEL'),self._basic_data)

    def testNumeric(self):
        self._test_of_data(('numeric SET','numeric GET','numeric GET_R','numeric DEL'),self._numeric_data)


class TestErrors(HybridStoreTestBase):
    def _invalid(self,name):
        return 'That is not a valid %s.' % name

    def testBadQuery(self):
        json = self._hs.send('DO SOMETHING INVALID;')
        self._json_error(json)
        self.assertEqual(json.get('response'),'Query seems well-formed, but it is unrecognized.')

    def testDropInvalidTree(self):
        json = self._hs.drop('t')
        self._json_error(json)
        self.assertEqual(json.get('response'),self._invalid('tree'))

    def testGetInvalidTree(self):
        json = self._hs.get('invalid','t')
        self._json_error(json)
        self.assertEqual(json.get('response'),self._invalid('tree'))

    def testInvalidLoad(self):
        json = self._hs.load('not_a_valid_file.rj','test')
        self._json_error(json)
        self.assertEqual(json.get('response'),self._invalid('file'))


class TestPersistence(HybridStoreTestBase):
    def _from_persistent(self):
        self._assert_get('wolf','Canis lupus','test')
        self._assert_get('earthworm','Lumbricus terrestris','test')
        self._assert_get('honey_bee','Apis mellifera','test')
        self._assert_get('cone_flower','Echinacea sp.','test')
        self._assert_get('daisy','Bellis perennis','test')
        self._assert_get('white_oak','Quercus alba','test')
        self._assert_get('acetic_acid','ethanoic acid','test')
        self._assert_get('caffeine','1,3,7-trimethyl-1H-purine-2,6(3H,7H)-dione','test')
        self._assert_get('brimstone','sulphur','test')
        self._assert_get('chalk','calcium carbonate (calcite)','test')
        self._assert_get('salt','sodium chloride','test')

    def testLoadCompressed(self):
        self._hs.load('tests/dictionary.rjc','test',compressed=True)
        self._from_persistent()

    def testLoadUncompressed(self):
        self._hs.load('tests/dictionary.rj','test')
        self._from_persistent()


class TestRange(HybridStoreTestBase):
    def _load_basic(self):
        self._hs.set(','.join([ "%s=%s" % (p[0],p[1]) for p in self._basic_data ]),'test')

    def testLimit(self):
        self._load_basic()
        json = self._hs.get_r('a','e','test',limit=2)
        self._json_ok(json)
        self.assertTrue(isinstance(json.get('response'),dict))
        self.assertEqual(len(json['response'].keys()),2)

    def testNoLimit(self):
        self._load_basic()
        json = self._hs.get_r('a','d','test')
        self._json_ok(json)
        self.assertTrue(isinstance(json.get('response'),dict))
        self.assertEqual(len(json['response'].keys()),4)


class TestSimple(HybridStoreTestBase):
    def testPing(self):
        json = self._hs.ping()
        self.assertEqual(json.get('response'),'PONG.')


if __name__ == '__main__':
    unittest.main()
