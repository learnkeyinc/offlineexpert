let details, shell;

let GKanID, courseName, previewURL, offlineExpertPrefix, courseID, assets, curriculum, videos2d, ISSMedia, ISSAssets, domainIDs, videos, domainGalleries, assetGalleries, glossary, glossaryJSON, expertBios, outlineTable, files;

let categories, filesToZip, totalSize, zip;

let maxSizeISS = 2100000000;

let threadStatuses;

let interval;

let thumbnails, intros, video;

video = document.getElementById("video");

let Promise = window.Promise;
  if (!Promise) {
      Promise = JSZip.external.Promise;
  }

let year = (new Date()).getFullYear();

// After the user enters the JSON in the fields, they click Verify to ensure it is valid JSON.
// If valid, the "Create files" button is enabled, and the fields are disabled
$("#verify").click(verifyJSON);

// When the user clicks "Prepare files," .
$("#parse").click(parseResults);

$("body").on("click", ".loadvideo", function () { loadVideo(this); });

$("#capture").click(captureThumbnail);

$("#commit").click(commitThumbnails);

$("#define").click(defineAssets);

// When the user clicks "Create"
$("#collect").click(collectAndDownload);

// When the user clicks "Retry failed downloads"
$("#retry").click(startDownloadAttempt);

$("#download").click(getZipFile)

function verifyJSON() {
    removeValidation();
    let result = true;
  $.each(["#shell","#details"], (i,e) => {
      try {
        JSON.parse($(e).val());
      $(e+"-container").addClass("has-success");
    } catch {
      $(e+"-container").addClass("has-error");
      result = false;
    }
  });
  if (result) {
    $("#parse").attr("disabled", false);
    $("#shell,#details,#verify").attr("disabled",true);            
    shell = $.parseJSON($("#shell").val());
    details = $.parseJSON($("#details").val());
  }
}

function removeValidation() {
    $("#shell-container,#details-container").removeClass((i,c) => {return (c.match(/(^|\s)has-\S+/g) || []).join(" ")});
}

function URLtoRel(url) {
  return url.replace(/^.*realcbt\/(\d{6})\/CD\/WinFlash\/(.*)$/,"./videos/$1/CD/WinFlash/$2")
}

function hostToFilename(host) {
  return host.replace(/.*\//,"");
}

function parseResults() {
  GKanID = details.Id;
  courseName = details.Name.trim();
  offlineExpertPrefix = courseName.toLowerCase().replace(/[`@$^&()+={}[\]|\\:;,/?]/g,"").split(/\W/).join("-").replace(/-{2,}/,"-");
  courseID = details.CourseNumber;
  [assets, curriculum, videos2d, ISSMedia, domainIDs, videos] = parseShell();

  // Preview video and 9xbuddy
  previewURL = details.VideoSrc;
  $("#previewlink").attr("href",previewURL).html(previewURL);
  $("#previewfilename").html(`${offlineExpertPrefix}-promo.mp4`);
  if (previewURL.includes("youtu")) {
    let youTubeID = youtube_parser(previewURL);            
    $("#9xbuddy").attr("href",`https://9xyoutube.com/watch?v=${youTubeID}`);
    $("#9xli").toggle();
    $("#preview").attr("src",`https://youtube.com/embed/${youTubeID}`);            
  }

  function youtube_parser(url){ // lifted from jeffreypriebe (found at https://stackoverflow.com/questions/3452546/how-do-i-get-the-youtube-video-id-from-a-url)
    var regExp = /^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*/;
    var match = url.match(regExp);
    return (match&&match[7].length==11)? match[7] : false;
  }
  
  // for ahk2exe
  $("#ahk2exefilename").html(`ahk2exe-${offlineExpertPrefix}.cmd`);
  
  // For iterations of offlineexpert-domain.html
  domainGalleries = domainIDs.reduce((s,v,i) => s + `<div class="gallery"><a href="./domains/${offlineExpertPrefix}-domain-${i+1}.html"><img src="./images/${offlineExpertPrefix}-domain-${i+1}.png" alt="Domain ${i+1}" width="300" height="auto"></a><div class="desc">${curriculum[i].name}<br><a href="./glossaries/${offlineExpertPrefix}-glossary.html">Glossary</a></div></div>\r`,``)
  assetGalleries = assets.reduce((s,v) => s + `<div class="gallery"><a href="./assets/${v.name}" title="${v.title}">${v.title}</a></div>\r`, ``)

  // For offlineexpert-glossary.html
  glossary = getGlossary(GKanID);
  glossaryJSON = JSON.stringify(glossary.map((v,i) => {return {def:v.def.trim(), con:v.con.trim()}}));

  // For offlineexpert-outline.html
  expertBios = details.ExpertList.reduce((s,v) => s + `<p>${v.Bio}</p>`, "");
  outlineTable = "<table>\n";
  $.each(curriculum, (iDomain,domain) => {
    outlineTable += `\t<tr class="domain"><td>${domain.name}</td><td>${secondsToHMS(domain.time)}</td></tr>\n`;
    $.each(domain.modules, (iModule,module) => {
      outlineTable += `\t<tr class="module"><td>${module.name}</td><td>${secondsToHMS(module.time)}</td></tr>\n`;
      $.each(module.buttons, (iButton,button) => {
        outlineTable += `\t<tr class="button"><td colspan="2">${button.name}</td></tr>\n`;
      });
    });
  });
  outlineTable += `<tr class="domain"><td>Total</td><td>${secondsToHMS(curriculum.reduce((t,v) => t + v.time))}</td></tr></table>`;

  // For intro thumbnails
  console.log("curriculum:",curriculum);
  intros = curriculum.map((domain) => domain.modules[0].buttons[0].videos[0]);

  // For ISS file
  ISSAssets = assets.reduce((s,v) => s + `Source: "..\\assets\\${v.name}"; DestDir: "{app}\\assets"; Flags: ignoreversion; Components: assets\n`, "")
  $("#issfilename").html(`${courseName}.iss`);

  // For .zip file
  $("#zipfilename").html(`offlineexpert-${offlineExpertPrefix}-setup.zip`);

  populateThumbnailPlaylist();

  initializeZip();

  $("#parse").attr("disabled",true);
  $("#commit,#capture").attr("disabled",false);
}

function initializeZip() {
  // Make zip file
  zip = JSZip();
}

function populateThumbnailPlaylist() {
  $("#playlist").empty();
  $.each(intros,(i,v) => {            
    $("#playlist").append($(`<tr><td id="playlist-${i+1}" class="loadvideo" data-url="${v.url}" data-domain="${i+1}">Domain ${i+1}</td></tr>`));
    $("#thumbnails").append($(`<div class="col-sm-3"><div id="thumbnail-${i+1}" class="thumbnail loadvideo" data-url="${v.url}" data-domain="${i+1}"><canvas id="canvas-${i+1}" style="width:100%;overflow:auto"></canvas><div class="caption">Domain ${i+1}</div></div></div>`));
  });
}

function loadVideo(e) {
  let domain = $(e).data("domain");
  let filename=`${offlineExpertPrefix}-domain-${domain}.png`;
  $("[id^=thumbnail-],[id^=playlist-]").removeClass("video-selected");
  $(`#thumbnail-${domain},#playlist-${domain}`).addClass("video-selected");
  video.src = $(e).data("url");
  video.crossOrigin = "Anonymous";
  $("#video").data("domain",domain);
  video.play();
}

video.onkeydown = (e) => { // hack the video player to only move short distance https://www.codespeedy.com/forward-and-backward-html5-video-player-javascript/
  switch (e.key) {
    case "a":
      video.currentTime -= 1/29;
      e.stopImmediatePropagation();
      e.preventDefault();
      break;
    case "d":
      video.currentTime += 1/29;
      e.stopImmediatePropagation();
      e.preventDefault();
      break;
  }
};

function captureThumbnail() {
  let domain = $("#video").data("domain");
  let canvas = document.getElementById(`canvas-${domain}`);
  let w = video.videoWidth;
  let h = video.videoHeight;
  canvas.width = w;
  canvas.height = h;
  let ctx = canvas.getContext('2d');
  ctx.drawImage(video, 0, 0, w, h);
  ctx.lineWidth = w/50;
  ctx.strokeStyle = "rgba(255,255,255,0.25)";
  ctx.fillStyle = "rgba(255,255,255,0.25)";
  // add triangle
  ctx.beginPath();
  let side = w/5;
  let centerToVertex = side * Math.sqrt(3) / 3;
  let angle = 2 * Math.PI / 3; // 120°
  for (let i = 0; i < 3; i++) {
    let x = w/2 + centerToVertex*Math.cos(i * angle);
    let y = h/2 + centerToVertex*Math.sin(i * angle);
    if (i == 0) {
      ctx.moveTo(x,y);            
    } else {
      ctx.lineTo(x,y);
    }
  }
  ctx.fill();
  // add circle
  ctx.beginPath();
  ctx.arc(w/2, h/2, w/7, 0, Math.PI*2);
  ctx.stroke();

  canvas.setAttribute('crossOrigin', 'anonymous');
  $(`#canvas-${domain}`).data("dataurl", canvas.toDataURL().split("base64,")[1]);
}

function commitThumbnails() {
  $("[id^=canvas-]").each((i,e) => {
    try {
      let domain = $(e).parent().data("domain");
      let dataurl = $(e).data("dataurl");
      if (!dataurl) { throw domain; }
      let image = 
      zip.file(`images/${offlineExpertPrefix}-domain-${domain}.png`, dataurl,{base64:true});
    } catch(e) {
      console.warn(`Domain ${e} thumbnail skipped. Maybe it was empty?`);
    }
  });          
  $("#capture,#commit").attr("disabled",true);
  $("#define").attr("disabled",false);
}

function defineAssets() {                
  files = [
    {
      host: "../templates/offlineexpert.ahk",
      category: "main",
      filename: `OfflineExpert for ${courseName}.ahk`,
      parts: [courseName, year, courseName, courseID, offlineExpertPrefix]
    },
    {
      host: "../templates/ahk2exe.cmd",
      category: "main",
      filename: `ahk2exe-${offlineExpertPrefix}.cmd`,
      parts: [courseName,courseName]
    },
    {
      host: "../templates/offlineexpert.iss",
      category: "main",
      filename: `${courseName}.iss`,
      parts: [courseName, courseName, offlineExpertPrefix, ISSAssets, ISSMedia]
    },
    {
      host:"../templates/offlineexpert-start.html",
      category: "main",
      filename: `${offlineExpertPrefix}-start.html`,
      parts: [courseName, offlineExpertPrefix, courseName, courseName, domainGalleries, offlineExpertPrefix, assetGalleries, year]
    },
    {
      host:"../templates/offlineexpert-glossary.html",
      category: "glossaries",
      filename: `${offlineExpertPrefix}-glossary.html`,
      folder: "glossaries",
      parts: [courseName, glossaryJSON, courseName, year]
    },
    {
      host:"../templates/offlineexpert-outline.html",
      category: "outlines",
      filename:`${offlineExpertPrefix}-outline.html`,
      folder: "outlines",
      parts: [courseName, courseName, details.Summary, expertBios, outlineTable, year]
    },
    // Fonts
    {host:"../assets/fonts/roboto-condensed-v14-latin-700.eot", category: "fonts",folder:"fonts"},
    {host:"../assets/fonts/roboto-condensed-v14-latin-700.svg", category: "fonts",folder:"fonts"},
    {host:"../assets/fonts/roboto-condensed-v14-latin-700.ttf", category: "fonts",folder:"fonts"},
    {host:"../assets/fonts/roboto-condensed-v14-latin-700.woff", category: "fonts",folder:"fonts"},
    {host:"../assets/fonts/roboto-condensed-v14-latin-700.woff2", category: "fonts",folder:"fonts"},
    {host:"../assets/fonts/roboto-condensed-v14-latin-regular.eot", category: "fonts",folder:"fonts"},
    {host:"../assets/fonts/roboto-condensed-v14-latin-regular.svg", category: "fonts",folder:"fonts"},
    {host:"../assets/fonts/roboto-condensed-v14-latin-regular.ttf", category: "fonts",folder:"fonts"},
    {host:"../assets/fonts/roboto-condensed-v14-latin-regular.woff", category: "fonts", folder:"fonts"},
    {host:"../assets/fonts/roboto-condensed-v14-latin-regular.woff2", category: "fonts", folder:"fonts"},
    {host:"../assets/fonts/roboto-v16-latin-700.eot", category: "fonts", folder:"fonts"},
    {host:"../assets/fonts/roboto-v16-latin-700.svg", category: "fonts", folder:"fonts"},
    {host:"../assets/fonts/roboto-v16-latin-700.ttf", category: "fonts", folder:"fonts"},
    {host:"../assets/fonts/roboto-v16-latin-700.woff", category: "fonts", folder:"fonts"},
    {host:"../assets/fonts/roboto-v16-latin-700.woff2", category: "fonts", folder:"fonts"},
    {host:"../assets/fonts/roboto-v16-latin-regular.eot", category: "fonts", folder:"fonts"},
    {host:"../assets/fonts/roboto-v16-latin-regular.svg", category: "fonts", folder:"fonts"},
    {host:"../assets/fonts/roboto-v16-latin-regular.ttf", category: "fonts", folder:"fonts"},
    {host:"../assets/fonts/roboto-v16-latin-regular.woff", category: "fonts", folder:"fonts"},
    {host:"../assets/fonts/roboto-v16-latin-regular.woff2", category: "fonts", folder:"fonts"},
    // Help
    {host:"../assets/help/OfflineExpert v1.2.doc", category: "help", folder:"help"},
    {host:"../assets/help/OfflineExpert v1.2.pdf", category: "help", folder:"help"},
    // Images
    {host:"../assets/images/bg_banner_index.jpg", category: "images", folder:"images"},
    {host:"../assets/images/lk_favicon.jpg", category: "images", folder:"images"},
    {host:"../assets/images/LK_logo_200.jpg", category: "images", folder:"images"},
    {host:"../assets/images/lk_square_icon.ico", category: "images", folder:"images"},
    {host:"../assets/images/lk_square_small.bmp", category: "images", folder:"images"},
    {host:"../assets/images/lk_square.jpg", category: "images", folder:"images"},
    {host:"../assets/images/lklogo_2015.png", category: "images", folder:"images"},
    // Text
    {host:"../assets/text/EULA.rtf", category: "text", folder:"text"},
    {host:"../assets/text/INFO.rtf", category: "text", folder:"text"},
    {host:"../assets/text/SUCCESS.rtf", category: "text", folder:"text"},
    // Videos
    ...videos,
    // Assets
    ...assets
  ];
            
  // Add domain HTML files
  $.each(curriculum, (i, domain) => {
    files.push({
      host:"../templates/offlineexpert-domain.html",
      category: "main",
      filename: `${offlineExpertPrefix}-domain-${i+1}.html`,
      folder: "domains",
      parts: [courseName, i+1, domain.id, JSON.stringify(videos2d[i]), domain.name, year]
    });          
  });

  console.log("files:",files);

  // get unique category values from files
  categories = [...new Set(files.map((v) => v.category))].sort();

  // Make checkboxes
  $.each(categories, (i,v) => {
    let categoryCount = files.reduce((t,f) => t += (f.category == v) ? 1 : 0, 0);
    $("#categories").append($(`<label class="checkbox-inline"><input id="checkbox-${v}" type="checkbox" value="${v}" checked>${v} <span class="badge">${categoryCount}</span></label>`));
  })
  
  $("#parse").attr("disabled",true);
  $("#categories,#collect").attr("disabled",false);
}

function collectAndDownload() {
  $("#collect").attr("disabled", true);
  
  let categoriesToZip = $("#categories [id^=checkbox-]:checked").map((_,e) => $(e).val()).get();
  
  totalSize = 0;
  filesToZip = files.filter((e) => categoriesToZip.includes(e.category));      

  // Add files to table
  $("#files").append($(`<table id="filestable" class="table table-condensed table-striped" width="100%"><thead><tr><th>File</th><th>Folder</th><th>Category</th><th title="HTTP status"><i class="glyphicon glyphicon-transfer"></i></th><th title="Download status"><i class="glyphicon glyphicon-cloud-download"></i></th><th title="Injection status"><i class="glyphicon glyphicon-pencil"></i></th><th title="Zip status"><i class="glyphicon glyphicon-compressed"></i></th></thead><tbody><tr></tr></tbody></table>`))

  $.each(filesToZip, (i,f) => {
    if (!filesToZip[i].filename) {
      filesToZip[i].filename = hostToFilename(filesToZip[i].host);
    }
    $("#filestable tbody").append($(`<tr id="file-${i}"><td>${f.filename}</td><td>${f.folder}</td><td>${f.category}</td><td id="httpstatus-${i}"></td><td id="downloadstatus-${i}"></td><td id="injectionstatus-${i}"></td><td id="zipstatus-${i}"></tr>`))
  })
  
  startDownloadAttempt();
}

function startDownloadAttempt() {
  let threads = +$("#threads").val(); // 1-10; add spinner
  let retries = +$("#retries").val();
  threadStatuses = [];

  // Start a number (threads) of downloads
  for (let i = 0; i < threads; i++) {
    threadStatuses.push(false);
    downloadAndZip(i, i, threads, retries);
  }

  interval = setInterval(checkStatus, 1000);

}

function checkStatus() {
  let threadsComplete = threadStatuses.reduce((b,v) => b && v, true);
  let total = filesToZip.length;
  let downloaded = filesToZip.reduce((t,o) => t + (o.downloaded ? 1:0), 0);
  let percentComplete = `${(downloaded/total*100).toFixed(1)}%`;

  $("#progressbar").css("width",percentComplete).addClass("active").attr("aria-valuenow",percentComplete).html(`${percentComplete} (${downloaded}/${total}, ${formatBytes(totalSize)})`);

  if (threadsComplete) {
    clearInterval(interval);
    if (total == downloaded) {
      $("#progressbar").removeClass("active").addClass("progress-bar-success");
      $("#download").attr("disabled",false);
      if (totalSize >= maxSizeISS) {
        $("#maxsizeiss").html(formatBytes(maxSizeISS));
        $(".isswarning").toggle();
      }
    } else {
      $("#progressbar").removeClass("active").addClass("progress-bar-warning");
      $("#retry").attr("disabled",false);
    }
    console.log("zip:", zip);
    return;
  } else {
    return;
  }
}

function formatBytes(a,b=2){if(0===a)return"0 Bytes";const c=0>b?0:b,d=Math.floor(Math.log(a)/Math.log(1024));return parseFloat((a/Math.pow(1024,d)).toFixed(c))+" "+["Bytes","KB","MB","GB","TB","PB","EB","ZB","YB"][d]} // https://stackoverflow.com/questions/15900485/correct-way-to-convert-size-in-bytes-to-kb-mb-gb-in-javascript

function getZipFile() {                   
  let writeStream = streamSaver.createWriteStream(`${courseName} OfflineExpert.zip`).getWriter();

  zip.generateInternalStream({type:"uint8array", streamFiles:$("#streamfiles").is(":checked"), compression:"DEFLATE", compressionOptions:{level:1}})
    .on("data", data => writeStream.write(data))
    .on("error", err => $("#status").append($(`<div class="alert alert-danger">${err}</div>`)))
    .on("end", () => writeStream.close())
    .resume();
}

async function downloadAndZip(iterator, thread, threads, retries) {
  let response, contents;
  let tries = 1;
  
  if (filesToZip[iterator]) {
    filesToZip[iterator].downloaded = false;
    while (tries++ <= retries && !filesToZip[iterator].downloaded) {
      updateTable("http", iterator, "active", `<i class="glyphicon spin glyphicon-repeat"></i>`);
      
      try {
        response = await fetch(filesToZip[iterator].host);
      } catch (e) {
        console.warn(e);
        updateTable("http", iterator, "warning", `<i class="glyphicon glyphicon-refresh"></i>`);
        continue;
      }

      if (response.ok) {
        updateTable("http", iterator, "success", `<i class="glyphicon glyphicon-ok"></i>`);
        
        updateTable("download", iterator, "active", `<i class="glyphicon spin glyphicon-repeat"></i>`);

        try {
          if (filesToZip[iterator].parts) {
            // Replacements required in a template file, so post-processing required
            contents = await response.text();
            contents = replaceParts(contents, filesToZip[iterator].parts);
            updateTable("injection", iterator, "success", `<i class="glyphicon glyphicon-ok"></i>`);
            contents = new Blob([contents], {type: "text/plain"});
          } else {
            // No replacements required, so no post-processing required
            updateTable("injection", iterator, "success", `<i class="glyphicon glyphicon-ban-circle"></i>`);
            contents = await response.blob();
          }
          totalSize += contents.size;
          filesToZip[iterator].downloaded = true;
        } catch (e) {
          console.warn(e);
          updateTable("download", iterator, "warning", `<i class="glyphicon glyphicon-refresh"></i>`);
          continue;
        }
      } else {
        updateTable("http", iterator, "warning", `<i class="glyphicon glyphicon-refresh"></i>`);  
        continue;
      }
    }
    
    if (filesToZip[iterator].downloaded) {
      updateTable("download", iterator, "success", `<i class="glyphicon glyphicon-ok"></i>`);
      zipFile(iterator, contents, retries);
    } else {
      updateTable("download", iterator, "danger", `<a class="glyphicon glyphicon-cloud-download" href="${filesToZip[iterator].host}"></a>`);
    }                   
  } else {
    // No more files to zip in this thread
    threadStatuses[thread] = true;
    return 1;
  }
  
  // get next file
  setTimeout(function () { downloadAndZip(iterator + threads, thread, threads, retries) }, 0); 
  return 1;        
}

function replaceParts(fn_contents, fn_parts) {
  $.each(fn_parts, (i, p) => {
    fn_contents = fn_contents.replace(`[Part ${i+1}]`,p);
  })
  return fn_contents;
}

function updateTable(idType, i, status, text) {
  $(`#${idType}status-${i}`).removeClass().addClass(status).html(text);
}

async function zipFile(i, contents, retries) {          
  let tries = 1;

  while (tries++ <= retries && !filesToZip[i].zipped) {
    updateTable("zip", i, "active", `<i class="glyphicon spin glyphicon-repeat"></i>`);     
    try {
      zip.file((filesToZip[i].folder ? filesToZip[i].folder + "/" : "") + filesToZip[i].filename, contents);
      filesToZip[i].zipped = true;
    } catch (e) {
      console.warn(e);
      updateTable("zip", i, "warning", `<i class="glyphicon glyphicon-refresh"></i>`);
      continue;
    }
  } 
  
  if (filesToZip[i].zipped) {
    updateTable("zip", i, "success", `<i class="glyphicon glyphicon-ok"></i>`);
  } else {
    updateTable("zip", i, "danger", `<i class="glyphicon glyphicon-remove"></i>`);
    filesToZip[i].downloaded = false;
  }

  return 1;
}

function secondsToHMS(seconds) {
  let s = seconds%60;
  let m = Math.floor(seconds/60)%60;
  let h = Math.floor(seconds/(60*60));
  let hms = [m,s];
  if (h > 0) {
    hms.unshift(h)
  }          
  let hmsString = hms.map(v => v.toString().padStart(2,0)).join(":");
  return hmsString;
}        

function getGlossary(id) {
  return $.ajax({
      "async": false,
    "url": `https://lms.onlineexpert.com/student/coursehomeapi/GetGlossary?Origin=https://lms.onlineexpert.com&Referer=https://lms.onlineexpert.com/Student/Home&courseId=${id}`,
    "method": "POST"
  }).responseJSON.result;
}

function parseShell() {
  /*
    Types:
      Section:
      1: Download 
        0:
      
      3: Assessment
        1: Assessment

      4: Videos
        1: Multiple videos

      Content:
      1:  Video
        3: Single video
        16: Multiple videos
  */
  let fn_assets = [];
  let fn_videos2d = [];
  let fn_curriculum = [];
  let fn_ISSMedia = [];
  let fn_domainIDs = [];
  let fn_videos = [];
  let path = {};
  try {
    $.each(shell.Lesson, (i, domain) => {  // 1 lesson = 1 domain
      // update current path
      path.i = [i,domain];
      ["j","k","l","m"].forEach(e => delete path[e]);

      fn_videos2d.push([]);
      fn_curriculum.push({
        name: domain.Name,
        modules:[],
        time:0
      })            
      $.each(domain.Section, (j, module) => { // 1 section = 1 module
        // update current path
        path.j = [j, module];
        ["k","l","m"].forEach(e => delete path[e]);

        switch (module.Type) {
          case "1": // File downloads
            $.each(module.Download, (k, download) => {
              // update current path
              path.k = [k, download];
              ["l","m"].forEach(e => delete path[e]);

              if (download.Url) {
                fn_assets.push({
                  title: download.Title,
                  category: "assets",
                  folder: "assets",
                  host: download.Url,
                  name: hostToFilename(download.Url),
                });
              }
            });
            break;
          case "3": // Assessment
            // Do nothing for now. Future implementation of assessments.
            break;
          case "4":  // Videos
            fn_videos2d[i].push(["",module.Name]);
            fn_curriculum[i].modules.push({
              name: module.Name,
              buttons:[],
              time:0
            });
            let m = fn_curriculum[i].modules.length - 1
            $.each(module.Content, (k, button) => { // 1 content = 1 button
              // update current path
              path.k = [k, button];
              ["l","m"].forEach(e => delete path[e]);

              if (button.Type != 1 || ![3,16].includes(+button.ContentType)) {
                return;
                // It's a lab, label, test, or something else
              }

              fn_curriculum[i].modules[m].buttons.push({
                name: button.Name,
                videos: [],
                time:0
              });
              let b = fn_curriculum[i].modules[m].buttons.length - 1;
              $.each(button.File, (l, file) => {
                // update current path
                path.l = [l, file];
                delete path.m;

                if (l == 0) {
                  fn_videos2d[i].push([file.Name,button.Name]);                        
                } else {
                  fn_videos2d[i].push([file.Name,""]);
                }
                let domainID = file.Url.replace(/^.*realcbt\/(\d{6})\/.*$/,"$1");
                fn_videos.push({
                  host: file.Url,
                  category: "videos",
                  folder: `videos/${domainID}/CD/WinFlash`
                })
                if (!fn_domainIDs.includes(domainID)) {
                  fn_domainIDs.push(domainID);
                  fn_curriculum[i].id = domainID;
                  fn_ISSMedia += `Source: "..\\videos\\${domainID}\\*"; DestDir: "{app}\\videos\\${domainID}"; Flags: ignoreversion recursesubdirs createallsubdirs; Components: media\r`;
                }
                fn_curriculum[i].modules[m].buttons[b].videos.push({
                  prefix: file.Name,
                  time: +file.Time,
                  url: file.Url
                });
                fn_curriculum[i].modules[m].buttons[b].time += +file.Time;
                fn_curriculum[i].modules[m].time += +file.Time;
                fn_curriculum[i].time += +file.Time;
              });
            });
            break;
        }
      });
    });
    return ([fn_assets, fn_curriculum, fn_videos2d, fn_ISSMedia, fn_domainIDs, fn_videos])
  } catch (e) {
    console.error(e,"path:",path);
  }
}