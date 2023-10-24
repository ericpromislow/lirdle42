What I did:

1. rails new gameapp --database=mysql
2. Update .gitignore
3. git init ; git add -A ; git ci -m "Created dir"
4. Edit gemfile to use sqlite3 in dev/test

5. Create the users and profile thing

6. rails generate model Profile theme:integer karma:float
7. rails generate scaffold User username:string email:string password:digest is_temporary:boolean profile_id:number

8. git push to placenta -- to get the basics worked out...

9. rails test:
- fails :
```
ActionView::Template::Error: Webpacker can't find application.js in /Users/ericp/lab/rails/cable05/gameapp/public/packs-test/manifest.json. Possible causes:
```
9.1. 
```
I ended up finding a fix for my issue through this link: https://discuss.rubyonrails.org/t/pretty-astonishing/76850
$ yarn remove @rails/webpacker
$ rm -rf ./node_modules
$ yarn add @rails/webpacker@^5.4.4
^ didn't work
$ yarn remove @rails/webpacker
$ npm install --save-dev @rails/webpacker
```

That didn't work. Try this:
```
$ rake assets:precompile ->
Cannot find package '@babel/plugin-proposal-private-methods' imported from /Users/ericp/lab/rails/cable05/gameapp/babel-virtual-resolve-base.js

$ npm install --save-dev @babel/plugin-proposal-private-methods
$ npm install --save-dev @babel/plugin-proposal-private-property-in-object
$ yarn
$ ./bin/webpack-dev-server
```

10. Gemfile dependency problems?
See https://github.com/learnenough/rails_tutorial_6th_edition_gemfiles/blob/master/sample_app/Gemfile

11. Postgres fun and games

> This disables the brain-dead postgres CLI, which clears the screen all the time
PAGER= psql ...

12. How to fix the uninitialized constant warnings:
Add the following to the gemfile:

```
gem "net-ftp", "~> 0.2.0", require: false
gem "net-http"
```

