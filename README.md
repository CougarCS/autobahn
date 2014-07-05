[Autobahn](http://autobahn.cougarcs.com/) is a social network for CougarCS, the Computer Science student
organisation and ACM Chapter at the University of Houston.

The purpose is to facilitate connecting people to projects and people with
skills.

## Dev

- install vagrant
- run

      vagrant up

- cp config.yml.example config.yml
- add a GitHub API token to config.yml in the `Auth::Github` section:
  - if you want to use a server on localhost:8586 for development, use

        plugins:
          "Auth::Github":
            client_id: "08ab5c7a5e8ee1449102"
            client_secret: "53bd83ea6a228297d934ddbd09adf83bb54228f0"

    in that section.
  - otherwise, register an application at <https://github.com/settings/applications>.
    Settings should be

        Homepage: http://autobahn.cougarcs.com/
        Authorization callback URL: http://localhost:8586/auth/github/callback

    change the callback URL to match the port you will run the application on (default: 8586)
- run the development server

      ./start_dev
- setup upstream for your git repo

      git remote add upstream https://github.com/zmughal/autobahn.git

- git pull upstream master
