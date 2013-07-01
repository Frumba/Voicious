###

Copyright (c) 2011-2013  Voicious

This program is free software: you can redistribute it and/or modify it under the terms of the
GNU Affero General Public License as published by the Free Software Foundation, either version
3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License along with this
program. If not, see <http://www.gnu.org/licenses/>.

###

class Camera extends Module
    constructor : (emitter) ->
        super emitter
        do @appendHTML
        @jqMainCams       = ($ '#mainCam')
        @jqVideoContainer = ($ 'ul#videos')
        @zoomCams         = { }
        @streams          = [ ]
        ($ 'button#joinConference').bind 'click', @enableCamera
        @emitter.on 'stream.create', @newStream
        @emitter.on 'stream.remove', @delStream
        @emitter.on 'stream.state', @changeStreamState
        @emitter.on 'camera.localstream', (event, video) =>
            video.muted = yes
            @newStream event, { video : video , uid : window.Voicious.currentUser.uid , local : yes }
        ($ window).on 'resize', () =>
            do @squareMainCam
            videos = ($ 'video')
            for video in videos
                @centerVideoTag { currentTarget : video }
        ($ document).on 'DOMNodeInserted', 'video', @centerVideoTag
        ($ '#feeds').delegate '.zoomBtn', 'click', (event) =>
            clickButton = ($ event.target)
            mainLi = clickButton.parents 'li.thumbnail-wrapper'
            video = (mainLi.find 'video')
            if video?
                @zoom (video.attr 'rel'), video
        do @squareMainCam

    squareMainCam : () =>
        @jqMainCams.width do @jqMainCams.height

    appendHTML  : () ->
        ($ '<div class="fill-height module" id="mainCam"></div>').appendTo '#modArea'
        $(window).trigger 'resize'

    delStream   : (event, user) =>
        if (@streams.indexOf user.id) >= 0
            do ($ "li#video_#{user.id}").remove
            @streams.splice user.id, 1
            for k, v of @zoomCams
                if k is user.id
                    @zoom user.id, undefined
                    return

    newStream : (event, data) =>
        @streams.push data.uid
        video = ($ data.video)
        if data.local? and data.local is true
                video.addClass 'flipH'
        video.addClass 'thumbnailVideo'
        video.attr 'rel', data.uid
        @emitter.trigger 'stream.display', video
        if Object.keys(@zoomCams).length == 0 and (not data.local? or not data.local)
            @zoom data.uid, video

    changeStreamState : (event, data) =>
        # Data.state = {audio : bool, video : bool}

    # Must set margin-left css propriety when adding a video tag to the page
    # Width is computed using video original size (640 * 480) since css value is wrong at this time
    centerVideoTag : (event) =>
        jqTag      = ($ event.currentTarget)
        marginleft = ((do jqTag.height) * 640 / 480) / 2
        jqTag.css 'margin-left', -marginleft
        do event.currentTarget.play

    enableCamera : () =>
        @emitter.trigger 'camera.enable'

    zoom : (uid, video) =>
        container    = ($ 'div#mainCam')
        container.removeClass 'hidden'
        for k, v of @zoomCams
            if k is uid
                do @zoomCams[uid].remove
                delete @zoomCams[uid]
                return
        if video?
            newVideo     = do video.clone
            newVideo.attr 'id', "zoomcam#{uid}"
            newVideo[0].volume = video[0].volume
            newVideo.removeClass 'thumbnailVideo'
            do newVideo[0].play
            container.append newVideo
            @zoomCams[uid] = ($ "video#zoomcam#{uid}")


if window?
    window.Camera = Camera
