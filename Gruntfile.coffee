module.exports = (grunt) ->
  grunt.initConfig data=
    pkg: grunt.file.readJSON 'package.json'
    rsync:
      options:
        args: ["--verbose", "--delete"]
        exclude: [".git*", "*.scss", "node_modules"]
        recursive: true
      rpi:
        options:
          src: "./"
          dest: "/home/nwittstock/paper/"
          host: "nwittstock@172.24.42.121"
      rpiconfig:
        options:
          src: "./configs/config.rpi.json"
          dest: "/home/nwittstock/paper/config.json"
          host: "nwittstock@172.24.42.121"

  grunt.loadNpmTasks 'grunt-rsync'
  grunt.registerTask 'rpi', ['rsync:rpi', 'rsync:rpiconfig']
