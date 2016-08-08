_  = require 'lodash'
kd = require 'kd'
ContentModal = require 'app/components/contentmodal'

module.exports = class UploadCSVSuccessModal extends ContentModal

  constructor: (options = {}, data) ->

    options = _.assign {}, options,
      cssClass: 'content-modal uploadcsvsuccess'
      title: 'Success'
      width: 600
      content: '''
        <div class='image-wrapper'>
        </div>
        <div class='content'>
          <div class='invites-sent'>
            Invites Sent!
          </div>
          <div class='body'>
            We have proccessed all your invitations, they should receive an email shortly.
          </div>
        </div>
      '''
      buttons:
        close:
          cssClass: 'GenericButton fr'
          title: 'Close'
          callback: =>
            @destroy()

    super options

  destroy: ->
    location.reload()
