;; TODO : make linking more automatic

;;; load the library in the dotemacs file using

;;; (autoload 'spf-mode "spf-mode" "Select spf-mode" t)
;;; (add-to-list 'minor-mode-alist '(spf-mode " spf"))
;;; the custom html theme must also be present to use this package.
;;; 
;;; this minor mode should be enabled on a per-file basis
;;; with the line
;;; # -*- eval: (spf-mode); -*-
;;; at the top of the file.


;;;###autoload
(define-minor-mode spf-mode
  "Minor mode for structured proof export or org-mode."
  :lighter " spf"

(org-num-mode)  

(defun org-link-describe (link desc)
  "Change how links are described to insert description automatically.
   See https://emacs.stackexchange.com/questions/13093/get-org-link-to-insert-link-description-automatically"
  (save-excursion
     (goto-char (point-min))
     (re-search-forward desc nil t)
     (if (file-exists-p link)
	 desc
    (read-string "Description: " desc)))
     )

(setf org-make-link-description-function #'org-link-describe)


;; Problem with dollars and -
(defun my-org-change-minus-syntax-fun ()
  "Change so that dollars and  minus do not make syntax problems"
  (modify-syntax-entry ?- "."))

(add-hook 'org-mode-hook #'my-org-change-minus-syntax-fun)

(setq org-html-postamble nil)

;; Copy from ox-html with small modifications as needed for spf exporter
(defun my-org-html-section (section contents info)
  "Transcode a SECTION element from Org to HTML.
CONTENTS holds the contents of the section.  INFO is a plist
holding contextual information."
  (let ((parent (org-export-get-parent-headline section)))
    ;; Before first headline: no container, just return CONTENTS.
    (if (not parent) contents
      ;; Get div's class and id references.
      (let* ((class-num (+ (org-export-get-relative-level parent info)
			   (1- (plist-get info :html-toplevel-hlevel))))
	     (section-number
	      (and (org-export-numbered-headline-p parent info)
		   (mapconcat
		    #'number-to-string
		    (org-export-get-headline-number parent info) "-"))))
        ;; Build return value.
	;; Modified for spf-mode
	(format "<div class=\"outline-text-%d\" id=\"text-%s\"></div>%s" 
		class-num
		(or (org-element-property :CUSTOM_ID parent)
		    section-number
		    (org-export-get-reference parent info))
		(or contents ""))))))


;; define new export menu entry
(org-export-define-derived-backend 'my-html 'html
  :translate-alist '((section . my-org-html-section))
  :menu-entry '(?h "Export to HTML"
		   ((?m "As spf-html file" my-org-html-export-to-html)))
  )


;;; Link handling


;; make link id


(defun my/org-add-ids-to-headlines-in-file ()
  "Add ID properties to all headlines in the current file which
do not already have one.
cf https://stackoverflow.com/questions/13340616/assign-ids-to-every-entry-in-org-mode"
  (interactive)
  (org-map-entries 'org-id-get-create))

(defun spf-get-ids ()
  "return a list of ids."
  (let ((matches))
    (save-match-data
      (save-excursion
        (widen)
        (goto-char 1)
        (while (search-forward-regexp "^:ID:[ \t]+\\([^\t\n]+\\)" nil t 1)
          (setq current-id (match-string 1))
          (setq current-heading (nth 4 (org-heading-components)))
          (push (list current-heading current-id) matches)))
      matches)))


(defun spf-ref ()
  "Begin by giving an id to every header that don't already have one.
Then, open Helm dialog to reference a header using its id number.
The header is refered by its id and when exported to html the link will
be renamed automatically to the right number sequence corresponding to the
heading.
"
  (interactive)
  (my/org-add-ids-to-headlines-in-file)
  (setq ids (nreverse (spf-get-ids)))

  (setq some-helm-source
        `((name . "HELM at the Emacs")
          (candidates . ,ids)
          (action . (lambda (candidate)
                      (helm-marked-candidates)))))


  (insert (concat  "[[#" (nth 0 (car (helm :sources '(some-helm-source)))) "]]"))
  )


;;;###autoload
(defun my-org-html-export-to-html
  (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a HTML file.
If narrowing is active in the current buffer, only export its
narrowed part.
Return output file's name."
  (interactive)
  (let* ((extension (concat "." (or (plist-get ext-plist :html-extension)
				    org-html-extension
				    "html")))
	 (file (org-export-output-file-name extension subtreep))
	 (org-export-coding-system org-html-coding-system))
    (org-export-to-file 'my-html file
      async subtreep visible-only body-only ext-plist)))

;;; Insert the details in html to have expandable proofs      
(defun my-insert-text-after-heading (text1 text2)
  "Insert text"
  (interactive)
  (setq loc-end-of-buffer (point-max))
  (setq do-break 0)
  (save-excursion
    (goto-char (point-min)) 
    (save-match-data
      (while (re-search-forward org-heading-regexp nil t)
	(unless (= (org-current-level) 1)
	  ;; handle limit cases
	  (save-excursion
	    (setq nextlevel (org-current-level))
	    (forward-line -1)
	    (setq prevlevel (org-current-level))
	    
	    (if ( <= nextlevel prevlevel )
	       (setq do-break 1)
	       (setq do-break 0)
	      )
	    )
	      (if (= do-break 0)
		(unless (member "noexport" (org-get-tags))
		  (save-excursion
		  ;; if there is already a begin details or end details block, go above the block
		  (forward-line -1)
		  (while (string-match-p (regexp-quote "spf_details" ) (thing-at-point 'line t))
		    (forward-line -5)
		   )
		  (end-of-line)
		  (newline)
		  ;; add the begin details html tag
		  (insert text1)
		  (newline)
		  )
		  )
		)
	      )
	)
       (while (re-search-forward org-heading-regexp nil t)
	(unless (= (org-current-level) 1)
	(unless (member "noexport" (org-get-tags))
	(save-excursion
	  (if (org-forward-heading-same-level 1) 
	      (forward-line -1)
	    (while (string-match-p (regexp-quote "spf_details" ) (thing-at-point 'line t))
	    (forward-line -5)
	   )
	    (newline)
	    ;; insert the end details blocks
	      (insert text2)
	      (newline))
	  )
	(save-excursion
	  (unless (org-forward-heading-same-level 1)
	    (unless (= (org-current-level) 1)
	    	    (outline-up-heading 1)
		    (org-forward-heading-same-level 1)
		    (while (string-match-p (regexp-quote "spf_details" ) (thing-at-point 'line t))
		    (forward-line -5)
		     )
		    (forward-line -1)
		    (newline)
		    ;; insert the end details block
		    (insert text2)
		    (newline)))
	  )
	  )
        ))))
  )

;; definition of begin details and end details org blocks to be exported in html
(setq npf-beginning-details "\#+begin_export html
 <details>
 <summary> </summary> 
\#+end_export 
\# spf_details \n")

(setq npf-end-details "\# end detail
\#+begin_export html
</details>
\#+end_export 
\# spf_detail \n")

(defun insert-details (backend)
  " insert beginning and end details"
  (my-insert-text-after-heading npf-beginning-details npf-end-details)
  )

(add-hook 'org-export-before-parsing-hook #'insert-details)

(defun org-replace-links-descs (&rest _) ; accepts, any number of 'unused'; arguments
  (interactive)
  (if (not org-num-mode)
      (message "org-num-mode not active")
    (goto-char (point-min))
    (while (not (stringp (org-next-link)))
      (let* ((context (org-element-context))
             (beg (org-element-property :begin context))
             (end (org-element-property :end context))
             (cbeg (org-element-property :contents-begin context))
             (cend (org-element-property :contents-end context))
             (raw-link (org-element-property :raw-link context))
             file
             num)
        (when (string-match  "\\(^*\\|:\\*\\)" raw-link)
          (save-excursion
            (org-link-open context)
            (unless org-num-mode (org-num-mode))
            (skip-chars-forward "*")
            ;; there can be multiple overlays so we filter out 'org-num' overlay
            (when (string-match "^file" raw-link)
              (setq file (nth 1 (split-string raw-link ":"))))
            (setq num (substring
                       (car
                        (delete nil
                                (mapcar (lambda (o)
                                          (when (overlay-get o 'org-num)
                                            (overlay-get o 'after-string)))
                                        (overlays-at (point)))))
                       0 -1)))
          (let ((new-desc (concat file (when file ":") num)))
            (if cbeg
                (replace-region-contents cbeg cend (lambda () new-desc))
              (goto-char (1- end))
              (insert "[" new-desc "]"))))))))

(defun my-org-export-dispatch ()
  (interactive)
  (when org-num-mode
    (org-replace-links-descs))
 (org-export-dispatch))
)

(provide 'spf-mode)
;; spf-mode.el ends here
