#!/bin/bash
zola build
git remote remove origin
git init
git add -A
git commit -a -m "update site $(date  --rfc-3339=seconds)"
git remote add origin git@github.com:archion/archion.github.io.git
git push origin master:dev --force
git push origin `git subtree split --prefix public master`:master --force
