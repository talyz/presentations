(require 'org)
(require 'ox-beamer)
(setq org-latex-listings 'minted)
(setq org-latex-pdf-process '("%latex -shell-escape -interaction nonstopmode -output-directory %o %f"
                              "%latex -shell-escape -interaction nonstopmode -output-directory %o %f"
                              "%latex -shell-escape -interaction nonstopmode -output-directory %o %f"))
(add-to-list 'org-beamer-environments-extra
             '("onlyenv" "O" "\\begin{onlyenv}%a" "\\end{onlyenv}"))
(add-to-list 'org-beamer-environments-extra
             '("onlyenv_block" "h" "\\begin{onlyenv}%a\\begin{block}{%h}" "\\end{block}\\end{onlyenv}"))
(add-to-list 'org-beamer-environments-extra
             '("tcolorbox" "T" "\\begin{tcolorbox}[title=%h,%O]" "\\end{tcolorbox}"))
(add-to-list 'org-beamer-environments-extra
             '("tcolorbox_no_title" "t" "\\begin{tcolorbox}[%O]" "\\end{tcolorbox}"))
(push '("" "xcolor" nil) org-latex-default-packages-alist)
(add-to-list 'org-latex-packages-alist '("newfloat" "minted"))
(setcar (seq-find (lambda (val)
                    (string-equal (cadr val) "hyperref"))
                  org-latex-default-packages-alist)
        "pdfborderstyle={/S/U/W 0.5},urlbordercolor=blue")
