# require landing-page

window.html5-redirection-landing-page = ({
    campaign-id or window?.mobiOneConstants?.campaignId
    creative
    suffix
    domain
    path
    pageId
    language
    on-will-transition or (-> true)
    on-subscribe-click or (-> true)
    double-confirmation or (-> false)
}:parameters)->

    if typeof! double-confirmation == \Boolean
        double-confirmation = -> true

    {add-click-listener, dispatch-event, techify-language, add-class, remove-class} = window.utils
    {any, camelize, each, filter, find, map, fold, pairs-to-obj, obj-to-pairs, unique} = window.prelude


    # calling page.changeLanguage is not necessary at load time
    if language.length == 2
        change-language language

    # tech team's LangID is different from ISO Codes
    language := techify-language language

    {populate, record-event, techify-language}:landing-page = window.landing-page do 
        {} <<< parameters <<< {
            get-extra-event-args: ->
                {} <<< landing-page.get-extra-event-args! <<< {
                    campaign-id: parse-int campaign-id
                    creative
                    page-id: parse-int page-id
                    page-language: language        
                    suffix
                }
        }

    open-landing-page = (trigger = {}, transition-event-args = {})!->

        # If cturl is missing we create it using page's main script arguements

        cturl = window?.mobiOneConstants?.query-params?.cturl

        path := path + "/" if path.length > 0 and path[path.length - 1] != "/" # for UAE we alway need / in path for directWAP to work
        domain := domain + "/" if domain[domain.length - 1] != "/"

        if !cturl
            cturl = "http://#{domain}#{path}" + '?CampaignID=' + campaign-id + '&ForcedPage=' + pageId + '&IAutoSub=go&skiphost=1'
            extra = (window?.mobiOneConstants?.query-params ? {})
                |> obj-to-pairs
                |> fold do 
                    (acc, [k, v]) -> 
                        acc + "&#{k}=#{v}"
                    ""
            cturl := cturl + extra


        url = cturl
        url += "&q42=#{mobi-one-constants.q42}"
        url += "&xm-userId=#{mobi-one-constants.user-id}" 
        url += "&xm-creative=#creative&xm-suffix=#suffix" 
        url += "&xm-sessionId=#{mobi-one-constants.session-id}" 
        url += "&xm-clientSessionId=#{mobi-one-constants.client-session-id}" 
        url += "&LangID=#{language}"
        
        detail =
            from-state: \default-state
            to-state: \opening-landing-page-state
            trigger:
                action: \click
                element: \button
            url

        record-event \transition, detail
        dispatch-event \x-mobi-one-before-transition, {detail}

        <- set-timeout _, 300
        window.location.href = url

    elements = 
        * id: \default-state
        * id: \double-confirmation
        * id: \confirm
        * id: \double-confirmation-no
          required: -> false
        * id: \container
          required: double-confirmation

    $$ = elements
        |> map ({id, required})->
            element = document.get-element-by-id id
            return [(camelize id), element] if !!element
            is-required = if !!required then required! else true
            throw "#{id} not found" if is-required
        |> filter -> !!it
        |> pairs-to-obj
  
    # equivalent to get-initial-state in react
    state = {
        container-id: \default-state
        name: \default-state
    }

    render = !->

        {
            container-id
            name
        }? = state

        # show the current state container and hide the rest
        containers = <[default-state double-confirmation]>     
        if !!(containers |> find (== container-id))
            new-class ="show-#{container-id}"
            $$.container.class-name = if ($$.container.class-name.index-of \show-) == -1 then "#{$$.container.class-name} #{new-class}" else ($$.container.class-name.replace /show-[a-z\-]*/g, new-class)
            containers
                |> map -> [it, $$[camelize it]]        
                |> each ([id, element])-> element?.style?.display = if id == container-id then "" else \none

        if !!parameters.render
            parameters.render state


    set-state = (parameters, trigger = {}, transition-event-args = {}) !->

        event-args =
            detail: {
                from-state: state.name
                to-state: parameters.name
                trigger
            }
        dispatch-event \x-mobi-one-before-transition, event-args

        return if !on-will-transition state, {} <<< state <<< parameters

        if !!state?.name and !!parameters?.name and state.name != parameters.name
            record-event \transition, {from-state: state.name, to-state: parameters.name, trigger}  <<< transition-event-args
            dispatch-event \x-mobi-one-transition, event-args

        state <<< parameters
        render!

        dispatch-event \x-mobi-one-set-state, event-args


    {
        get-ready: (callback) -> 
            <- window.add-event-listener \load
 
            populate ...            

            add-click-listener $$.confirm, (e, trigger) -> 
                return if !on-subscribe-click e, trigger
                open-landing-page trigger

            if !!$$.double-confirmation-no
                add-click-listener do 
                    $$.double-confirmation-no
                    (, trigger) -> set-state {container-id: \default-state, name: \default-state}

            (document.get-elements-by-class-name \subscribe) |> map (element) ->
                (e, trigger) <- add-click-listener element
                if double-confirmation!
                    set-state {container-id: \double-confirmation, name: \double-confirmation}
                else
                    return if !on-subscribe-click e, trigger
                    open-landing-page trigger

            start-recording-tap -> {} <<< landing-page.get-extra-event-args! <<< {
                creative
                suffix
                campaign-id
                state: state.name
            }
            

            callback ... if !!callback

        record-event
        set-state
        get-state: -> state

        change-language: (iso-code) ->
            change-language iso-code
            # LangID query string parameter in MobiWAP pages is not the standard ISO Code
            # mapping if ISO codes to LangID is defined utils.ls
            language := window.utils.techify-language iso-code
    }   