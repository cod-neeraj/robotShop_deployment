import http from 'k6/http';
import { check } from 'k6';

// 🔧 Load pattern
export const options = {
  stages: [
    { duration: '1m', target: 100 }, 
    { duration: '2m', target: 300 }, 
    { duration: '3m', target: 700 },
    { duration: '5m', target: 1000 }, 
    { duration: '2m', target: 0 },     
  ],
  thresholds: {
    http_req_failed: ['rate<0.1'],
  },
};

const BASE_URL = 'http://aadccb9646afd4d2dbc30327da688d3d-1321323893.ap-south-1.elb.amazonaws.com';
const PRODUCT_URLS = [
  '/product/HPTD',
  '/product/SHCE',
  '/product/CNA',
];

export default function () {

  let res1 = http.get(`${BASE_URL}/`);
  check(res1, {
    'home ok': (r) => r.status === 200,
  });

  const product = PRODUCT_URLS[Math.floor(Math.random() * PRODUCT_URLS.length)];

  let res2 = http.get(`${BASE_URL}${product}`);
  check(res2, {
    'product ok': (r) => r.status === 200,
  });

}