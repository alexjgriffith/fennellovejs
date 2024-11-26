(local fennel (require :lib.fennel))

(local help "fennellovejs: 
    A tool for assembling love.js projects without relying on npm / node. 
    For the full project please see https://github.com/Davidobot/love.js 

usage: 
    fennellovejs [love-file] [project-name] [opts]

opts:
  -v (--version) Version of the Game. Will be included in file name.
  -o (--output-directory) Target directory. Defaults to PWD
  -t (--text-colour) Text Colour. Defaults to \"240,234,214\"
  -c (--canvas-colour) Canvas Colour. Defaults to \"54,69,79\"
  -a (--author) Author (Shows up on loading page).
  -w (--width) Canvas Width (game width in conf). Defaults to 800
  -h (--height) Canvas Height (game height in conf). Defaults to 600
  -r (--run) Set flag if you want to run a local copy on port 8000
  -d (--debug) Set flag for debug info
  -h (--help) Display this text

eg: 

Pack up sample.love
\tfennellovejs sample.love sample
\t> sample-web.zip

Pack up sample.love version 0.1.0
\tfennellovejs sample-0.1.0.love sample -v 0.1.0
\t> sample-0.1.0-web.zip

Pack up sample.love and set the background colour to black
\tfennellovejs sample-0.1.0.love sample -v 0.1.0 -c \"0,0,0\"
\t> sample-0.1.0-web.zip

Pack up sample.love and set the author to \"Sample Name\"
\tfennellovejs sample-0.1.0.love sample -a \"Sample Name\"
\t> sample-web.zip")

(local default-options {:version {:short :v :value "11.5"}
                        :output-directory {:short :o :value "."}
                        :text-colour {:short :t :value [240 234 214]}
                        :canvas-colour {:short :c :value [54 69 79]}
                        :author {:short :a :value ""}
                        :width {:short :w :value 800}
                        :height {:short :h :value 600}
                        :run {:short :r :value false}
                        :debug {:short :d :value false}
                        :help {:short :h :value false}})



(fn pp [...]
  (each [_ value (ipairs [...])]
    (print (fennel.view value))))

(fn error [string ...]
  (print (string.format (.. "ERROR: " string "\n\n" help) ...))
  (os.exit -1))

(fn parse-options [options defaults start end]
  (local short-opts (collect [option {: short } (pairs defaults)] (values short option)))
  (local output-opts (collect [option {: value } (pairs defaults)] (values option value)))
  (fn get-value [str]
    (when (~= (string.sub str 1 1) "-") str))
  (fn get-long-option [str]
    (when (and (= (string.sub str 1 1) "-") (= (string.sub str 2 2) "-"))
      (let [opt (string.sub str 3 (# str))]
        (if (not (. output-opts opt))
            (error "Flag `%s` not valid flag. Try --help." opt)
            opt))))
  (fn get-short-options [str short-opts]
    (when (and (= (string.sub str 1 1) "-") (~= (string.sub str 2 2) "-"))
      (let [options-string (string.sub str 2 (# str))]
        (values (icollect [char (string.gmatch options-string "." )]
                  (if (not (. short-opts char))
                      (error "Flag `%s` not valid flag. Try --help." char)
                  (. short-opts char)))
                (- (# str) 1)))))
  (var last-option nil)
  (for [i start end]
    (let [option (. options i)]
      (let [value (get-value option)
            long-option (get-long-option option)
            (short-options number-options) (get-short-options option short-opts)]
        (if (and long-option (not last-option))
            (set last-option long-option)
            (and short-options (= 1 number-options) (not last-option))
            (set last-option (. short-options 1))            
            (and short-options)
            (each [index opt (ipairs short-options)]
              (if (= index (# short-options))
                  (set last-option opt)
                  (if (= :boolean (type (. output-opts opt)))
                      (tset output-opts opt true)
                      (error "Flag `%s` expects an argument." opt))))
            (and value last-option)
            (do (tset output-opts last-option value)
                (set last-option nil))
            ))))
  (when last-option
    (if (= :boolean (type (. output-opts last-option)))
        (tset output-opts last-option true)
              (error "Flag `%s` expects an argument." last-option))
          )
  output-opts)

;; https://datatracker.ietf.org/doc/html/rfc9562
;; xxxxxxxx-xxxx-4xxx-9xxx-xxxxxxxxxxxx
(fn uuid4 []
  (local hex [:0 :1 :2 :3 :4 :5 :6 :7 :8 :9 :A :B :C :D :E :F])
  (fn hex-count [l] (faccumulate [n "" i 1 l] (.. n (. hex (math.random 16)))))
  (.. (hex-count 8) "-"
      (hex-count 4) "-4"
      (hex-count 3) "-9"
      (hex-count 3) "-"
      (hex-count 12)))

(fn main [args]
  (local love-file (. args 1))
  (local project-name (. args 2))
  (when (not (and love-file project-name))
    (error "Fennellovejs expects at least two arguments."))
  ;; check to make sure love-file exists
  (local f (io.open love-file))  
  (if (not f)
      (error "Love2d file `%s` cannot be found." love-file)
      (io.close f))
  (local options (parse-options args default-options 3 (# args)))
  
  
  
  )

(main [...])

