(local _loader (require :luarocks.loader))
(local lfs (require :lfs))

(fn ls [dir fun?]
  (local fun (or fun? (fn [x] x)))
  (icollect [f (lfs.dir dir)]
    (when (and (~= f ".") (~= f"..")) (fun f))))

(fn find-root [depth?]
  (let [make-up-dir #(faccumulate [o "." i 1 $] (.. "../" o ))
        check-main #(if (= $ :main.lua) $)
        depth (or depth? 5)
        cdir (lfs.currentdir)
        dir (faccumulate [out false k 0 (- depth 1)]
              (let [dir (make-up-dir k)]
                (if out
                    out
                    (and (not out) (> (# (ls dir check-main)) 0))
                    dir)))]
    (var ret nil)
    (when dir
      (lfs.chdir dir)
      (set ret (lfs.currentdir))
      (lfs.chdir cdir))
    ret))

(fn in-dir [dir callback ...]
  (lfs.mkdir dir)
  (local cdir (lfs.currentdir))
  (lfs.chdir dir)
  (callback cdir ...))

{: find-root : in-dir}


