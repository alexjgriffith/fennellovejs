// this is generated using template-preload . the only change is to replace the file name preload.js.metadata
// with game.metadata
  var LoveState = typeof LoveState != 'undefined' ? LoveState : {};

  if (!LoveState['expectedDataFileDownloads']) {
    LoveState['expectedDataFileDownloads'] = 0;
  }

  LoveState['expectedDataFileDownloads']++;
  (() => {
    // Do not attempt to redownload the virtual filesystem data when in a pthread or a Wasm Worker context.
    var isPthread = typeof ENVIRONMENT_IS_PTHREAD != 'undefined' && ENVIRONMENT_IS_PTHREAD;
    var isWasmWorker = typeof ENVIRONMENT_IS_WASM_WORKER != 'undefined' && ENVIRONMENT_IS_WASM_WORKER;
    if (isPthread || isWasmWorker) return;
    function loadPackage(metadata) {

      var PACKAGE_PATH = '';
      if (typeof window === 'object') {
        PACKAGE_PATH = window['encodeURIComponent'](window.location.pathname.toString().substring(0, window.location.pathname.toString().lastIndexOf('/')) + '/');
      } else if (typeof process === 'undefined' && typeof location !== 'undefined') {
        // web worker
        PACKAGE_PATH = encodeURIComponent(location.pathname.toString().substring(0, location.pathname.toString().lastIndexOf('/')) + '/');
      }
      var PACKAGE_NAME = 'game.data';
      var REMOTE_PACKAGE_BASE = 'game.data';
      if (typeof LoveState['locateFilePackage'] === 'function' && !LoveState['locateFile']) {
        LoveState['locateFile'] = LoveState['locateFilePackage'];
        err('warning: you defined LoveState.locateFilePackage, that has been renamed to LoveState.locateFile (using your locateFilePackage for now)');
      }
      var REMOTE_PACKAGE_NAME = LoveState['locateFile'] ? LoveState['locateFile'](REMOTE_PACKAGE_BASE, '') : REMOTE_PACKAGE_BASE;
var REMOTE_PACKAGE_SIZE = metadata['remote_package_size'];

      function fetchRemotePackage(packageName, packageSize, callback, errback) {
        
        LoveState['dataFileDownloads'] ??= {};
        fetch(packageName)
          .catch((cause) => Promise.reject(new Error(`Network Error: ${packageName}`, {cause}))) // If fetch fails, rewrite the error to include the failing URL & the cause.
          .then((response) => {
            if (!response.ok) {
              return Promise.reject(new Error(`${response.status}: ${response.url}`));
            }

            if (!response.body && response.arrayBuffer) { // If we're using the polyfill, readers won't be available...
              return response.arrayBuffer().then(callback);
            }

            const reader = response.body.getReader();
            const iterate = () => reader.read().then(handleChunk).catch((cause) => {
              return Promise.reject(new Error(`Unexpected error while handling : ${response.url} ${cause}`, {cause}));
            });

            const chunks = [];
            const headers = response.headers;
            const total = Number(headers.get('Content-Length') ?? packageSize);
            let loaded = 0;

            const handleChunk = ({done, value}) => {
              if (!done) {
                chunks.push(value);
                loaded += value.length;
                LoveState['dataFileDownloads'][packageName] = {loaded, total};

                let totalLoaded = 0;
                let totalSize = 0;

                for (const download of Object.values(LoveState['dataFileDownloads'])) {
                  totalLoaded += download.loaded;
                  totalSize += download.total;
                }

                LoveState['setStatus']?.(`Downloading data... (${totalLoaded}/${totalSize})`);
                return iterate();
              } else {
                const packageData = new Uint8Array(chunks.map((c) => c.length).reduce((a, b) => a + b, 0));
                let offset = 0;
                for (const chunk of chunks) {
                  packageData.set(chunk, offset);
                  offset += chunk.length;
                }
                callback(packageData.buffer);
              }
            };

            LoveState['setStatus']?.('Downloading data...');
            return iterate();
          });
      };

      function handleError(error) {
        console.error('package error:', error);
      };

      var fetchedCallback = null;
      var fetched = LoveState['getPreloadedPackage'] ? LoveState['getPreloadedPackage'](REMOTE_PACKAGE_NAME, REMOTE_PACKAGE_SIZE) : null;

      if (!fetched) fetchRemotePackage(REMOTE_PACKAGE_NAME, REMOTE_PACKAGE_SIZE, (data) => {
        if (fetchedCallback) {
          fetchedCallback(data);
          fetchedCallback = null;
        } else {
          fetched = data;
        }
      }, handleError);

    function runWithFS(LoveState) {

      function assert(check, msg) {
        if (!check) throw msg + new Error().stack;
      }
LoveState['FS_createPath']("/", "home", true, true);
LoveState['FS_createPath']("/home", "web_user", true, true);
LoveState['FS_createPath']("/home/web_user", "love", true, true);
LoveState['FS_createPath']("/home/web_user/love", "lib", true, true);
        LoveState['FS_createPath']("/home/web_user/love", "src", true, true);
        LoveState['FS_createPath']("/home/web_user/love", "assets", true, true);

      /** @constructor */
      function DataRequest(start, end, audio) {
        this.start = start;
        this.end = end;
        this.audio = audio;
      }
      DataRequest.prototype = {
        requests: {},
        open: function(mode, name) {
          this.name = name;
          this.requests[name] = this;
          LoveState['addRunDependency'](`fp ${this.name}`);
        },
        send: function() {},
        onload: function() {
          var byteArray = this.byteArray.subarray(this.start, this.end);
          this.finish(byteArray);
        },
        finish: function(byteArray) {
          var that = this;
          // canOwn this data in the filesystem, it is a slide into the heap that will never change
          LoveState['FS_createDataFile'](this.name, null, byteArray, true, true, true);
          LoveState['removeRunDependency'](`fp ${that.name}`);
          this.requests[this.name] = null;
        }
      };

      var files = metadata['files'];
      for (var i = 0; i < files.length; ++i) {
        new DataRequest(files[i]['start'], files[i]['end'], files[i]['audio'] || 0).open('GET', files[i]['filename']);
      }

      function processPackageData(arrayBuffer) {
        assert(arrayBuffer, 'Loading data file failed.');
        assert(arrayBuffer.constructor.name === ArrayBuffer.name, 'bad input to processPackageData');
        var byteArray = new Uint8Array(arrayBuffer);
        var curr;
        // Reuse the bytearray from the XHR as the source for file reads.
          DataRequest.prototype.byteArray = byteArray;
          var files = metadata['files'];
          for (var i = 0; i < files.length; ++i) {
            DataRequest.prototype.requests[files[i].filename].onload();
          }          LoveState['removeRunDependency']('datafile_game.data');

      };
      LoveState['addRunDependency']('datafile_game.data');

      if (!LoveState['preloadResults']) LoveState['preloadResults'] = {};

      LoveState['preloadResults'][PACKAGE_NAME] = {fromCache: false};
      if (fetched) {
        processPackageData(fetched);
        fetched = null;
      } else {
        fetchedCallback = processPackageData;
      }

    }
    if (LoveState['calledRun']) {
      runWithFS(LoveState);
    } else {
      if (!LoveState['preRun']) LoveState['preRun'] = [];
      LoveState["preRun"].push(runWithFS); // FS is not initialized yet, wait for it
    }

    LoveState['removeRunDependency']('game.metadata');
  }

  function runMetaWithFS() {
    LoveState['addRunDependency']('game.metadata');
    var REMOTE_METADATA_NAME = LoveState['locateFile'] ? LoveState['locateFile']('game.metadata', '') : 'game.metadata';
    fetch(REMOTE_METADATA_NAME)
      .then((response) => {
        if (response.ok) {
          return response.json();
        }
        return Promise.reject(new Error(`${response.status}: ${response.url}`));
      })
      .then(loadPackage);
  }

  if (LoveState['calledRun']) {
    runMetaWithFS();
  } else {
    if (!LoveState['preRun']) LoveState['preRun'] = [];
    LoveState["preRun"].push(runMetaWithFS);
  }

  })();
