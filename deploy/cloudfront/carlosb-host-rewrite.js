// CloudFront Function (event type: viewer-request, runtime: cloudfront-js-2.0)
// Attach it to the DEFAULT behavior of the carlosb.dev distribution (E2DV1F1KKLSNTM).
//
// The distribution answers for *.carlosb.dev and every host reads the same S3 bucket
// root. This function looks at the Host header and maps each project subdomain to its
// own prefix in the bucket:
//
//   https://minillm.carlosb.dev/x       →  /minillm/x
//   https://brusselator.carlosb.dev/x   →  /brusselator/x
//   https://carlosb.dev/anything        →  unchanged (the curriculum)
//
// Only ONE function can be associated per event type, so this single function replaces
// minillm-host-rewrite.js from the MiniLLM-CPP repo: it keeps that behaviour and adds
// brusselator. To add a new project later, add one line to SUBDOMAINS.
//
// It runs before the cache lookup, so the cache key is the rewritten path and sites
// never share cached objects.
var SUBDOMAINS = {
  'minillm.carlosb.dev': '/minillm',
  'brusselator.carlosb.dev': '/brusselator'
};

function handler(event) {
  var request = event.request;
  var host = request.headers.host ? request.headers.host.value : '';
  var prefix = SUBDOMAINS[host];

  if (prefix) {
    var uri = request.uri || '/';
    // S3 (REST origin) has no automatic "index.html" for folders: add it.
    if (uri.charAt(uri.length - 1) === '/') {
      uri = uri + 'index.html';
    }
    request.uri = prefix + uri;
  }

  return request;
}
