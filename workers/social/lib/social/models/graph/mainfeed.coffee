{Graph} = require './index'
QueryRegistry = require './queryregistry'
{race} = require "bongo"
module.exports = class Member extends Graph

  @fetchAll:(requestOptions, callback)->
    throw "EEEEEEE" if not requestOptions.withExempt?
    console.log "requestOptions =========================="
    console.log requestOptions
    console.log "// requestOptions ======================="
    {group:{groupName, groupId}, startDate, client, facet} = requestOptions

    options =
      groupId : groupId
      to  : startDate
      limitCount : 20

    facetQuery = groupFilter = ""

    if facet and facet isnt "Everything"
      options.facet = facet
      facetQuery += "AND content.name = {facet}"

    if groupName isnt "koding"
      options.groupName = groupName
      groupFilter = "AND content.group! = {groupName}"

    @getExemptUsersClauseIfNeeded requestOptions, (err, exemptClause)=>
      query = QueryRegistry.activity.public facetQuery, groupFilter, exemptClause
      @fetch query, options, (err, results) =>
        if err then return callback err
        if results? and results.length < 1 then return callback null, []
        resultData = (result.content.data for result in results)
        @objectify resultData, (objecteds)=>
          @getRelatedContent objecteds, requestOptions, callback

  @getRelatedContent:(results, options, callback)->
    tempRes = []
    {group:{groupName, groupId}, client} = options
    console.log "options"
    console.log options


    console.log "results"
    console.log results



    collectRelations = race (i, res, fin)=>
      id = res.id

      @fetchRelatedItems id, (err, relatedResult)=>
        if err
          return callback err
          fin()
        else
          tempRes[i].relationData =  relatedResult
          fin()
    , =>
      if groupName == "koding"
        @removePrivateContent client, groupId, tempRes, callback
      else
        callback null, tempRes

    for result in results
      tempRes.push result
      collectRelations result

  @fetchRelatedItems: (itemId, callback)->
    query = """
      start koding=node:koding("id:#{itemId}")
      match koding-[r]-all
      return all, r
      order by r.createdAtEpoch DESC
      """
    @fetchRelateds query, callback

  @fetchRelateds:(query, callback)->
    @fetch query, {}, (err, results) =>
      console.log arguments
      if err then callback err
      resultData = []
      for result in results
        type = result.r.type
        data = result.all.data
        data.relationType = type
        resultData.push data

      @objectify resultData, (objected)->
        respond = {}
        for obj in objected
          type = obj.relationType
          if not respond[type] then respond[type] = []
          respond[type].push obj

        callback err, respond


  @getSecretGroups:(client, callback)->
    JGroup = require '../group'
    JGroup.some
      $or : [
        { privacy: "private" }
        { visibility: "hidden" }
      ]
      slug:
        $nin: ["koding"] # we need koding even if its private
    , {}, (err, groups)=>
      if err then return callback err
      else
        if groups.length < 1 then callback null, []
        secretGroups = []
        checkUserCanReadActivity = race (i, {client, group}, fin)=>
          group.canReadActivity client, (err, res)=>
            secretGroups.push group.slug if err
            fin()
        , -> callback null, secretGroups
        for group in groups
          checkUserCanReadActivity {client: client, group: group}

  # we may need to add public group's read permission checking
  @removePrivateContent:(client, groupId, contents, callback)->
    console.log "contents"
    console.log contents

    if contents.length < 1 then return callback null, contents
    @getSecretGroups client, (err, secretGroups)=>
      console.log "secretGroups"
      console.log err, secretGroups
      if err then return callback err
      if secretGroups.length < 1 then return callback null, contents
      filteredContent = []
      for content in contents
        filteredContent.push content if content.group not in secretGroups
      console.log "filteredContent"
      console.log filteredContent
      return callback null, filteredContent
