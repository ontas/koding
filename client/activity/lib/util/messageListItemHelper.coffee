whoami               = require 'app/util/whoami'
React               = require 'kd-react'
ProfileTextContainer = require 'app/components/profile/profiletextcontainer'
isMyPost             = require 'app/util/isMyPost'

module.exports = helper =
  prepareThreadTitle: (channel) ->

    purpose = channel.get 'purpose'

    if purpose
      return <span className="purpose">{purpose}</span>

    preview = channel.get 'participantsPreview'
    count   = channel.get 'participantCount'

    shouldBeGrouped = no

    if count is 1
      sample = preview
    else
      # filter out logged in user.
      sample = preview.filter (acc) -> acc.get('_id') isnt whoami()._id
      shouldBeGrouped = yes  if count > 2

    if shouldBeGrouped
      origins = helper.getParticipantOrigins channel
      nameCount = origins.length

      children = []

      origins.forEach (origin, index) ->
        children.push helper.makeProfileText origin
        children.push helper.getSeparatorPartial count, nameCount, index

      children.push helper.getPlusMorePartial count, nameCount  if count > nameCount + 1
    else
      children = helper.makeProfileText sample.get 0

    return \
      <span>{children}</span>


  getParticipantOrigins: (channel) ->

    { lastMessage, participantsPreview, participantCount } = channel.toJS()

    lastMessageOwner = lastMessage.account

    origins = if isMyPost lastMessage then [] else [lastMessageOwner]

    filtered = participantsPreview.filter (p) ->
      return not (p._id in [whoami()._id, lastMessageOwner._id])

    origins = (origins.concat filtered).slice 0, 3

    return origins.map (origin) -> constructorName: 'JAccount', id: origin._id


  makeProfileText: (origin) ->

    # if it's immutable turn it to regular object.
    origin = origin.toJS()  if typeof origin.toJS is 'function'

    return \
      <ProfileTextContainer origin={origin} />


  getSeparatorPartial: (participantCount, nameCount, position) ->

    thereIsDifference = !!(participantCount - nameCount - 1)

    switch
      when (nameCount - position) is (if thereIsDifference then 1 else 2)
        return ' & '
      when position < nameCount - 1
        return ', '


  getPlusMorePartial: (participantCount, nameCount) ->
    text = " #{participantCount - nameCount - 1} more"

    return \
      <span>{text}</span>



