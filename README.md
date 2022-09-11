# spf-mode
emacs minor mode to write structured proofs using org-mode.

According to its inventor, structured proof are "A method of writing proofs is described that makes it harder to prove things
that are not true. The method, based on hierarchical structuring, is simple and practical." They were first described by Leslie Lamport in his article [How to Write a Proof](https://lamport.azurewebsites.net/pubs/lamport-how-to-write.pdf). This article has a sequel [How to Write a 21st Century Proof](https://lamport.azurewebsites.net/pubs/proof.pdf) with more ideas on the same theme.

This repository propose one way to code structured proofs using org-mode. I do not exactly follow Lamport's way of doing structured proof and this repository is hacky at best. Use at your own discretion.

An example of structured proof constructed with this mode can be found in the "examples" directory.

## Installation

To install, copy `spf-mode.el` and `white_clean.theme` in your dotemacs directory. Load the file `spf-mode.el` and import it with 

    (autoload 'spf-mode "spf-mode" "Select spf-mode" t)
    (add-to-list 'minor-mode-alist '(spf-mode " spf"))

## Dependencies

[org-mode](https://orgmode.org/)
[Helm](https://github.com/emacs-helm/helm)


## Usage

Write `# -*- eval: (spf-mode); -*-` at the top of the org file that contains the proof. 
The `white_clean.theme` provided must be used as html theme for this package to work as expected, see the example file.

`spf-mode` define a new export tool accessible via `C-c e h m` to generate the html file.

`spf-mode` also define a function `spf-ref` that can be used to easily refer to other steps in the proof. `spf-ref` use [Helm](https://github.com/emacs-helm/helm), it needs to be installed.

## Warning

This is an ongoing project and may contain a lot of bugs, but for now this works for me.
I am not an expert at emacs elisp and the code is probably horrible.
