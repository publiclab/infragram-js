# infragram-js

The code behind (and in front of) Infragram.org -- providing multispectral image compositing in the browser, as well as image saving online.

### Deprecation warning

We are seeking to replace the interactive interface at https://infragram.org/sandbox/ with a self-contained JavaScript application at:

https://github.com/publiclab/infragram

The new `infragram` repository is separate from the file-storage systems in this Node-based system. We plan to make the `infragram` interface linkable to various storage back-ends, including PublicLab.org.

The new system is far more modularly written and easier to read & maintain. We'd love help completing it!


### Developers

To get started,

    $ git clone --recursive https://github.com/publiclab/infragram-js.git
    $ cd infragram-js/public
    $ make
    $ ./run-linux-mac.sh
    $ firefox http://localhost:8000

To run the whole node server:

* you'll need nodejs, npm, and mongodb -- ubuntu/debian: `sudo apt-get install nodejs npm mongodb`
* install node modules with `npm install`
* run `sudo node app.js` or `sudo nodejs app.js` from the root directory.
* navigate to http://localhost:8001/sandbox/

You'll need coffeescript (`sudo npm install coffee-script -g`) to compile the javascript source. After editing the various .coffee files in the public directory, run make to compile them:

* `cd public`
* `make`


