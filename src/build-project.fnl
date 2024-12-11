;; build-project

;; depends on luafilesystem and lua-zip
;; luarocks install --local luafilesystem
;; sudo apt-install libzip-dev
;; luarocks install --local lua-zip

;; (local {: build-project : list-files : make-love-file} (require :build-project))
;; (list-files :examples/repl [{:dir "/src" :recursive true :include-directories true}])

(local _loader (require :luarocks.loader))

(fn file-list [directory? opts? into?]
  (let [directory (or directory? ".")
        lfs (require :lfs)
        default-opts {:match-regex false
                      :recursive false
                      :include-directories false
                      :callback false
                      :unique false}
        opts (collect [key value (pairs default-opts)]
               (values key (or (. (or opts? {}) key) value)))
        into (or into? [])]
    (fn contains [tab key x]
      (accumulate [ret false _ val (ipairs tab)] (if (= (. val key) x) true ret)))
    (icollect [file (lfs.dir directory) &into into]
      (let [dfile (.. directory "/" file)]
      (when (and (~= (file:sub 1 1) ".") (~= (file:sub 1 1) "#"))
        (let [{: mode : modification : size}
              (lfs.attributes dfile)
              ret {:file dfile : mode : size  : modification}]
          (match mode
            :directory
            (match (values opts.include-directories opts.recursive)
              (true true)
              (do
                (file-list dfile opts into)
                ret)
              (true false)
              ret
              (false true)
              (do
                (file-list dfile opts into)
                nil))
            :file
            (when (and (or (not opts.match-regex)
                           (string.find dfile opts.match-regex))
                       (or (not opts.unique)
                           ;; expensive!!
                           (not (contains into :file dfile))))
              (match  opts.callback
                true (opts.callback ret)
                false ret))
            )))))))

(fn multi-file-list [root tab into?]
  (local lfs (require :lfs))
  (local into (or into? []))
  (each [_ {: dir &as opts} (ipairs tab)]
    (when (lfs.attributes (.. root dir))
      (file-list (.. root dir) opts into)))
  into)

(local match-strings {:fnllua "%.[fl][nu][la]$"
                      :fnl "%.fnl$"
                      :lua "%.lua$"})

(local example-file-list
       [
        {:dir "examples/repl" :recursive false :match-regex "%.lua$"}
        {:dir "examples/repl/assets" :root "examples/repl"}
        {:dir "examples/repl/lib" :root "examples/repl" :match-regex "%.lua$"}
        {:dir "examples/repl/lib" :root "examples/repl" :match-regex "%.fnl$"}
        {:dir "examples/repl/src" :root "examples/repl" :match-regex "%.fnl$"}
        {:dir "examples/repl/src" :root "examples/repl" :match-regex match-strings.lua}
        ])

;;(multi-file-list example-file-list)

(fn strip-root [file-list key root]
  (each [_ file (ipairs file-list)]
    (tset file key (: (. file key) :gsub root "")))
  file-list)

(fn build-metadata [file-list outfile root?]
  (local root (or root? ""))
  (var start 0)
  (var end 0)
  (var str "{\"files\":[")
  (with-open [fout (io.open outfile :w)]
    (each [_ file (ipairs file-list)]
      ;; you can write to a temp file location in callback and set the alt-file
      ;; in the return value. This alt file will get written to the actual
      ;; data out, but it will appear as file in the metadata
      (with-open [fin (io.open (.. root (or file.alt-file file.file)) :r)]
        (fout:write (fin:read "*all")))
      (set end (+ end file.size))
      (set str (.. str (string.format
                        "{\"filename\":\"/home/web_user/love%s\",\"start\":%d,\"end\":%d},"
                        file.file
                        start
                        end)))
      (set start end)))
  (.. (str:sub 1 (- (# str) 1)) (string.format "],\"remote_package_size\":%d}" end)))

(fn save-string [string filename]
  (with-open [fout (io.open filename :w)]
    (fout:write string)
    (fout:flush)))

(fn list-files [root? files?]
  (local root (or root? "."))
  (-> (if files?
          (multi-file-list root files?)
          (file-list root {:recursive true}))
      (strip-root :file root)
      ((fn [t] (table.sort t (fn [a b] (< a.file b.file))) t))))

(fn build-project [root? out-dir? files?]
  (local root (or root? "."))
  (local out-dir (or out-dir? ""))
  (-> (list-files root files?)
      (build-metadata (.. out-dir :game.data) root)
      (save-string (.. out-dir :game.metadata))))

(fn make-love-file [root? out-file? files?]
  (local zip (require :brimworks.zip))
  (local root  (or root? "."))
  (local out-file  (or out-file? "game.love"))
  (local files (list-files root files?))
  (local zip-file (assert (zip.open out-file zip.CREATE)))
  (each [_ {: file : alt-file} (ipairs files)]
    (zip-file:add (: (or alt-file file) :gsub "^/" "") "file" (.. root file)))
  (zip-file:close))

(fn love-file-to-project [love-file out-file?]
  (let [out-file (or out-file? "")
        lfs (require :lfs)
        {: size} (lfs.attributes love-file)]
    (-> (string.formt "{\"files\":[{\"filename\":\"/home/web_user/love/%s\",\"start\":%d,\"end\":%d}],\"remote_package_size\":%d}"
                      :game.data 0 size size)
        (save-string (.. out-file :game.metadata)))
    (with-open [fin (io.open love-file :r)
                fout (io.open (.. out-file :game.data) :w)]
      (fout:write (fin:read :*all))
      (fout:flush))))

{: build-project : make-love-file : list-files : match-strings : love-file-to-project}
