--[[
https://www.manhuadb.com/manhua/598
-- xpath 语法
https://www.runoob.com/xpath/xpath-syntax.html
  ]]

local json = require "modules.json"
function getinfo()
  mangainfo.url = MaybeFillHost(module.RootURL, url)
  http.cookies.values['isAdult'] = '1'
  if http.get(mangainfo.url) then
    local x = TXQuery.Create(http.document)
    if mangainfo.title == '' then
      -- mangainfo.title=x.xpathstring('//h1[@class="comic-title"]')
       mangainfo.title = x.xpathstring('//meta[@property="og:novel:book_name"]/@content')
    end
    mangainfo.coverlink=MaybeFillHost(module.rooturl,x.xpathstring('//div[@class="cover"]/img/@src'))
    mangainfo.authors=x.xpathstring('//meta[@property="og:novel:author"]/@content')
    mangainfo.genres=x.xpathstring('//meta[@property="og:novel:category"]/@content')
    mangainfo.status = MangaInfoStatusIfPos(x.xpathstring('//div[@class="info"]/p[@class="tip"]/span[contains(., "状态")]/span'), '连载中', '已完结');
    mangainfo.summary=x.xpathstring('//meta[@property="og:description"]/@content')

    -- 选择第二个符合条件的json字符串
    local s=x.xpathstring('//script[@type="application/ld+json"][2]')
    -- 解析json字符串
    -- x.parsehtml(s)
    -- v=x.xpathstring('json(*).name') --name
    -- v=x.xpathstring('json(*).hasPart[1].version') --not work
    local t = json.decode(s)
    for _, item in ipairs(t.hasPart[1].hasPart) do
      mangainfo.chapterlinks.add(item.url)
      mangainfo.chapternames.add(item.issueNumber)
    end
    return no_error
  else
    return net_problem
  end
end

function getpagenumber()
  task.pagelinks.clear()
  http.headers.values['Referer'] = module.rooturl .. task.link
  if http.get(MaybeFillHost(module.rooturl, url)) then
    local x=TXQuery.Create(http.Document)
    --<div class="d-none vg-r-data" data-page="1" data-host="https://i2.manhuadb.com" data-num="2" data-preload_num="3" data-push_url='/manhua/598/613_6691.html' data-ccid="613" data-id="6691" data-d="598" data-total="181" data-img_pre="/ccbaike/613/6691/"></div>
    local data_host=x.xpathstring('//div[@class="d-none vg-r-data"]/@data-host')
    local data_img_pre=x.xpathstring('//div[@class="d-none vg-r-data"]/@data-img_pre')
    local f = io.open('manhuadb.log', 'w')
    f:write(MaybeFillHost(module.rooturl, url)..'\n')
    f:write(data_host..'\n')
    f:write(data_img_pre..'\n')

    local tmp_links = {}

    local s = x.xpathstring('//script[contains(., "img_data")]')
    -- f:write(s)
    -- f:write('\ndecode\n')
    local text = DecodeBase64(GetBetween("img_data = '", "';", s))
    -- f:write(text)
    local t = json.decode(text)
    for _, item in pairs(t) do
      --https://i2.manhuadb.com/ccbaike/613/6691/15_hotqaegw.jpg
      task.pagelinks.add(data_host.. data_img_pre .. item.img)
      table.insert(tmp_links, data_host.. data_img_pre .. item.img)
    end
    -- task.pagecontainerlinks.text = MaybeFillHost(module.rooturl, url)
    task.pagecontainerlinks.values[0] = http.cookies.text

    f:write(table.concat(tmp_links, '\n'))
    f:close()
  else
    return false
  end
  return true
end


-- useless
function getnameandlink()
  local s = module.RootURL .. string.format('/danhsach/P%s/index.html?sort=1', IncStr(url))
  if http.get(s) then
    return no_error
  else
    return net_problem
  end
end

function BeforeDownloadImage()
  http.headers.values['Referer'] = module.rooturl
  return true
end

function Init()
  m=NewModule()
  m.category='Raw'
  m.website='manhuadb'
  m.rooturl='https://www.manhuadb.com'
  m.lastupdated='May 23, 2018'
  m.ongetinfo='getinfo'
  m.ongetpagenumber='getpagenumber'
  -- m.ongetdirectorypagenumber='getdirectorypagenumber'
  m.ongetnameandlink='getnameandlink'
  -- m.OnBeforeDownloadImage = 'BeforeDownloadImage'
  m.sortedlist = true
end
