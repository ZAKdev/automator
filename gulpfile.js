var gulp = require("gulp"),
    watch = require("gulp-watch"),
    stylus = require('gulp-stylus'),
    nib    = require('nib'),
    jshint = require('gulp-jshint'),
    imageop = require('gulp-image-optimization'),
    connect = require("gulp-connect"),
    webshot = require('webshot'),
    config = require("./config.json");

gulp.task('connect', function() {
  connect.server({
    root: './',
    livereload: true,
    port: 8000
  });
});

gulp.task('html', function () {
  gulp.src(config.path+'/*.html')
    .pipe(connect.reload());
});

gulp.task('lint', function() {
  return gulp.src(config.path+'/js/*.js')
    .pipe(connect.reload())
    .pipe(jshint())
    .pipe(jshint.reporter('jshint-stylish'));
});

gulp.task('stylus-assets', function () {
    return gulp.src(config.creative+'/assets/styl/*.styl')
        .pipe(stylus({
            compress: false,
            use: nib()
        }))
       .pipe(gulp.dest(config.creative+'/assets/css'))
       .pipe(connect.reload());
});

gulp.task('stylus-zshared', function () {
    return gulp.src(config.creative+'/z-shared/styl/*.styl')
        .pipe(stylus({
            compress: false,
            use: nib()
        }))
       .pipe(gulp.dest(config.creative+'/z-shared/css'))
       .pipe(connect.reload());
});

gulp.task('imagemin-assests', function(cb) {
    gulp.src([config.creative+'/assets/img/*.png', config.creative+'/assets/img/*.jpg', config.creative+'/assets/img/*.gif', config.creative+'/assets/img/*.jpeg'])
        .pipe(imageop({
            optimizationLevel: 100,
            progressive: true,
            interlaced: true
        })).pipe(gulp.dest(config.creative+'/assets/img')).on('end', cb).on('error', cb);
});

gulp.task('imagemin-zshared', function(cb) {
    gulp.src([config.creative+'/z-shared/img/*.png', config.creative+'/z-shared/img/*.jpg', config.creative+'/z-shared/img/*.gif', config.creative+'/z-shared/img/*.jpeg'])
        .pipe(imageop({
            optimizationLevel: 100,
            progressive: true,
            interlaced: true
        })).pipe(gulp.dest(config.creative+'/z-shared/img')).on('end', cb).on('error', cb);
});

gulp.task('watch', function() {
    gulp.watch(config.path+'/*.html', ['html']);
    gulp.watch([config.creative+'/assets/css/*.css', config.creative+'/z-shared/css/*.css', config.path+'/css/*.css'], ['html']);
    gulp.watch(config.creative+'/assets/styl/*.styl', ['stylus-assets']);
    gulp.watch(config.creative+'/z-shared/styl/*.styl', ['stylus-zshared']);
    gulp.watch(config.path+'/js/*.js', ['lint', 'html']);
});

gulp.task('screenshoot', function(){
    var screenshotPath = config.path.replace(/\//g, '-').replace('creatives-', '').replace('default', '');
    var options = {
        screenSize: {
          width: 320
        },
        renderDelay: "2000",
        quality: "100",
        userAgent: 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 3_2 like Mac OS X; en-us)'
          + ' AppleWebKit/531.21.20 (KHTML, like Gecko) Mobile/7B298g'
    };
    webshot(config.url+'?state=operator-selection', 'screenshots/'+config.name+'/'+screenshotPath+'operator-selection.png', options, function(err) {
    });
    webshot(config.url+'?state=default-state', 'screenshots/'+config.name+'/'+screenshotPath+'default-state.png', options, function(err) {
    });
    webshot(config.url+'?state=double-confirmation', 'screenshots/'+config.name+'/'+screenshotPath+'double-confirmation.png', options, function(err) {
    });
    webshot(config.url+'?state=subscription-polling', 'screenshots/'+config.name+'/'+screenshotPath+'subscription-polling.png', options, function(err) {
    });
    webshot(config.url+'?state=number-entry', 'screenshots/'+config.name+'/'+screenshotPath+'number-entry.png', options, function(err) {
    });
    webshot(config.url+'?state=pin-entry', 'screenshots/'+config.name+'/'+screenshotPath+'pin-entry.png', options, function(err) {
    });
    webshot(config.url+'?state=mo', 'screenshots/'+config.name+'/'+screenshotPath+'mo.png', options, function(err) {
    });
    webshot(config.url+'?state=congrats', 'screenshots/'+config.name+'/'+screenshotPath+'congrats.png', options, function(err) {
    });
});

gulp.task('newcreative', function(){
    gulp.src('creatives/_template/assets/**/*', {base:"./creatives/_template/"})
    .pipe(gulp.dest(config.creative))

    gulp.src('creatives/_template/index.html')
    .pipe(gulp.dest(config.path))

    gulp.src('creatives/_template/main.js')
    .pipe(gulp.dest(config.path+'/js'))
});

gulp.task('copy', function(){
    gulp.src(config.creative+'/**/*', {base:"./"})
    .pipe(gulp.dest(config.mobi))
});

gulp.task('start', ['connect', 'watch']);
gulp.task('compress', ['imagemin-assests', 'imagemin-zshared']);
gulp.task('shoot', ['screenshoot']);
gulp.task('new', ['newcreative']);