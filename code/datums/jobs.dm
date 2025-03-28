/datum/job
	var/name = null
	var/list/alias_names = null
	var/initial_name = null
	var/linkcolor = "#0FF"
	var/wages = 0
	var/limit = -1
	var/add_to_manifest = 1
	var/no_late_join = 0
	var/no_jobban_from_this_job = 0
	var/allow_traitors = 1
	///can you roll this job if you rolled antag with a non-traitor-allowed favourite job (e.g.: prevent sec mains from forcing only captain antag rounds)
	var/allow_antag_fallthrough = TRUE
	var/allow_spy_theft = 1
	var/can_join_gangs = TRUE
	var/cant_spawn_as_rev = 0 // For the revoltion game mode. See jobprocs.dm for notes etc (Convair880).
	var/cant_spawn_as_con = 0 // Prevents this job spawning as a conspirator in the conspiracy gamemode.
	var/requires_whitelist = 0
	var/mentor_only = 0
	var/requires_supervisor_job = null // Enter job name, this job will only be present if the entered job has joined already
	var/needs_college = 0
	var/assigned = 0
	var/high_priority_job = 0
	var/low_priority_job = 0
	var/cant_allocate_unwanted = 0
	var/receives_miranda = 0
	var/receives_implant = null //Will be a path.
	var/receives_disk = 0
	var/receives_security_disk = 0
	var/receives_badge = 0
	var/announce_on_join = 0 // that's the head of staff announcement thing
	var/radio_announcement = 1 // that's the latejoin announcement thing
	var/list/alt_names = list()
	var/slot_card = /obj/item/card/id
	var/spawn_id = 1 // will override slot_card if 1
	// Following slots support single item list or weighted list - Do not use regular lists or it will error!
	var/list/slot_head = list()
	var/list/slot_mask = list()
	var/list/slot_ears = list(/obj/item/device/radio/headset) // cogwerks experiment - removing default headsets
	var/list/slot_eyes = list()
	var/list/slot_suit = list()
	var/list/slot_jump = list()
	var/list/slot_glov = list()
	var/list/slot_foot = list()
	var/list/slot_back = list(/obj/item/storage/backpack)
	var/list/slot_belt = list(/obj/item/device/pda2)
	var/list/slot_poc1 = list() // Pay attention to size. Not everything is small enough to fit in jumpsckets.
	var/list/slot_poc2 = list()
	var/list/slot_lhan = list()
	var/list/slot_rhan = list()
	var/list/items_in_backpack = list() // stop giving everyone a free airtank gosh
	var/list/items_in_belt = list() // works the same as above but is for jobs that spawn with a belt that can hold things
	var/list/access = list(access_fuck_all) // Please define in global get_access() proc (access.dm), so it can also be used by bots etc.
	var/mob/living/mob_type = /mob/living/carbon/human
	var/datum/mutantrace/starting_mutantrace = null
	var/change_name_on_spawn = 0
	var/special_spawn_location = null
	var/bio_effects = null
	var/objective = null
	var/rounds_needed_to_play = 0 //0 by default, set to the amount of rounds they should have in order to play this
	var/map_can_autooverride = 1 // if set to 0 map can't change limit on this job automatically (it can still set it manually)
	/// Does this job use the name and appearance from the character profile? (for tracking respawned names)
	var/uses_character_profile = TRUE
	/// The faction to be assigned to the mob on setup uses flags from factions.dm
	var/faction = 0

	var/short_description = null //! Description provided when a player hovers over the job name in latejoin menu
	var/wiki_link = null //! Link to the wiki page for this job

	New()
		..()
		initial_name = name

	proc/special_setup(var/mob/M, no_special_spawn)
		if (!M)
			return
		if (receives_miranda)
			M.verbs += /mob/proc/recite_miranda
			M.verbs += /mob/proc/add_miranda
			if (!isnull(M.mind))
				M.mind.miranda = DEFAULT_MIRANDA
		M.faction |= src.faction

		SPAWN(0)
			if (receives_implant && ispath(receives_implant))
				var/mob/living/carbon/human/H = M
				var/obj/item/implant/I = new receives_implant(M)
				if (src.receives_disk && ishuman(M))
					if (H.back?.storage)
						var/obj/item/disk/data/floppy/D = locate(/obj/item/disk/data/floppy) in H.back.storage.get_contents()
						if (D)
							var/datum/computer/file/clone/R = locate(/datum/computer/file/clone/) in D.root.contents
							if (R)
								R.fields["imp"] = "\ref[I]"

			var/give_access_implant = ismobcritter(M)
			if(!spawn_id && (length(access) > 0 || length(access) == 1 && access[1] != access_fuck_all))
				give_access_implant = 1
			if (give_access_implant)
				var/obj/item/implant/access/I = new /obj/item/implant/access(M)
				I.access.access = src.access.Copy()
				I.uses = -1

			if (src.special_spawn_location && !no_special_spawn)
				var/location = special_spawn_location
				if (!istype(special_spawn_location, /turf))
					location = pick_landmark(special_spawn_location)
				if (!isnull(location))
					M.set_loc(location)

			if (ishuman(M) && src.bio_effects)
				var/list/picklist = params2list(src.bio_effects)
				if (length(picklist))
					for(var/pick in picklist)
						M.bioHolder.AddEffect(pick)

			if (ishuman(M) && src.starting_mutantrace)
				var/mob/living/carbon/human/H = M
				H.set_mutantrace(src.starting_mutantrace)

			if (src.objective)
				var/datum/objective/newObjective = new /datum/objective/crew(src.objective, M.mind)
				boutput(M, "<B>Your OPTIONAL Crew Objectives are as follows:</b>")
				boutput(M, "<B>Objective #1</B>: [newObjective.explanation_text]")

			if (M.client && src.change_name_on_spawn && !jobban_isbanned(M, "Custom Names"))
				//if (ishuman(M)) //yyeah this doesn't work with critters fix later
				var/default = M.real_name + " the " + src.name
				var/orig_real = M.real_name
				M.choose_name(3, src.name, default)
				if(M.real_name != default && M.real_name != orig_real)
					phrase_log.log_phrase("name-[ckey(src.name)]", M.real_name, no_duplicates=TRUE)

// Command Jobs

ABSTRACT_TYPE(/datum/job/command)
/datum/job/command
	linkcolor = "#00CC00"
	slot_card = /obj/item/card/id/command
	map_can_autooverride = 0
	can_join_gangs = FALSE

	special_setup(mob/M, no_special_spawn)
		. = ..()
		var/image/image = image('icons/mob/antag_overlays.dmi', icon_state = "head", loc = M)
		image.appearance_flags = PIXEL_SCALE | RESET_ALPHA | RESET_COLOR | RESET_TRANSFORM | KEEP_APART
		get_image_group(CLIENT_IMAGE_GROUP_HEADS_OF_STAFF).add_image(image)

/datum/job/command/captain
	name = "Captain"
	limit = 1
	wages = PAY_EXECUTIVE
	high_priority_job = 1
	receives_miranda = 1
	allow_traitors = 0
	cant_spawn_as_rev = 1
	announce_on_join = 1
	allow_spy_theft = 0
	allow_antag_fallthrough = FALSE
	wiki_link = "https://wiki.ss13.co/Captain"

	slot_card = /obj/item/card/id/gold
	slot_belt = list(/obj/item/device/pda2/captain)
	slot_back = list(/obj/item/storage/backpack/captain)
	slot_jump = list(/obj/item/clothing/under/rank/captain)
	slot_suit = list(/obj/item/clothing/suit/armor/captain)
	slot_foot = list(/obj/item/clothing/shoes/swat/captain)
	slot_glov = list(/obj/item/clothing/gloves/swat/captain)
	slot_head = list(/obj/item/clothing/head/caphat)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses)
	slot_ears = list(/obj/item/device/radio/headset/command/captain)
	slot_poc1 = list(/obj/item/disk/data/floppy/read_only/authentication)
	items_in_backpack = list(/obj/item/storage/box/id_kit,/obj/item/device/flash)
	rounds_needed_to_play = 30

	New()
		..()
		src.access = get_all_accesses()


	derelict
		//name = "NT-SO Commander"
		name = null
		limit = 0
		slot_suit = list(/obj/item/clothing/suit/armor/captain/centcomm)
		slot_jump = list(/obj/item/clothing/under/misc/turds)
		slot_head = list(/obj/item/clothing/head/centhat)
		slot_belt = list(/obj/item/tank/emergency_oxygen/extended)
		slot_glov = list(/obj/item/clothing/gloves/fingerless)
		slot_back = list(/obj/item/storage/backpack/NT)
		slot_mask = list(/obj/item/clothing/mask/gas)
		slot_eyes = list(/obj/item/clothing/glasses/thermal)
		items_in_backpack = list(/obj/item/crowbar,/obj/item/device/light/flashlight,/obj/item/camera,/obj/item/gun/energy/egun)

		special_setup(var/mob/living/carbon/human/M)
			..()
			if (!M)
				return
			M.show_text("<b>Something has gone terribly wrong here! Search for survivors and escape together.</b>", "blue")

/datum/job/command/head_of_personnel
	name = "Head of Personnel"
	limit = 1
	wages = PAY_IMPORTANT
	wiki_link = "https://wiki.ss13.co/Head_of_Personnel"

	allow_spy_theft = 0
	allow_antag_fallthrough = FALSE
	receives_miranda = 1
	cant_spawn_as_rev = 1
	announce_on_join = 1


#ifdef SUBMARINE_MAP
	slot_suit = list(/obj/item/clothing/suit/armor/hopcoat)
	slot_back = list(/obj/item/storage/backpack)
	slot_belt = list(/obj/item/device/pda2/hop)
	slot_jump = list(/obj/item/clothing/under/suit/hop)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_ears = list(/obj/item/device/radio/headset/command/hop)
	slot_poc1 = list(/obj/item/pocketwatch)
	items_in_backpack = list(/obj/item/storage/box/id_kit,/obj/item/device/flash,/obj/item/storage/box/accessimp_kit)
#else
	slot_back = list(/obj/item/storage/backpack)
	slot_belt = list(/obj/item/device/pda2/hop)
	slot_jump = list(/obj/item/clothing/under/suit/hop)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_ears = list(/obj/item/device/radio/headset/command/hop)
	slot_poc1 = list(/obj/item/pocketwatch)
	items_in_backpack = list(/obj/item/storage/box/id_kit,/obj/item/device/flash,/obj/item/storage/box/accessimp_kit)
#endif

	New()
		..()
		src.access = get_access("Head of Personnel")
		return

/datum/job/command/head_of_security
	name = "Head of Security"
	limit = 1
	wages = PAY_IMPORTANT
	requires_whitelist = 1
	receives_miranda = 1
	allow_traitors = 0
	allow_spy_theft = 0
	can_join_gangs = FALSE
	cant_spawn_as_con = 1
	cant_spawn_as_rev = 1
	announce_on_join = 1
	receives_disk = 1
	receives_security_disk = 1
	receives_badge = 1
	receives_implant = /obj/item/implant/health/security/anti_mindhack
	items_in_backpack = list(/obj/item/device/flash)
	wiki_link = "https://wiki.ss13.co/Head_of_Security"


#ifdef SUBMARINE_MAP
	slot_jump = list(/obj/item/clothing/under/rank/head_of_security/fancy_alt)
	slot_suit = list(/obj/item/clothing/suit/armor/vest)
	slot_back = list(/obj/item/storage/backpack/security)
	slot_belt = list(/obj/item/device/pda2/hos)
	slot_poc1 = list(/obj/item/storage/security_pouch) //replaces sec starter kit
	slot_poc2 = list(/obj/item/requisition_token/security)
	slot_foot = list(/obj/item/clothing/shoes/swat)
	slot_head = list(/obj/item/clothing/head/hos_hat)
	slot_ears = list(/obj/item/device/radio/headset/command/hos)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses/sechud)


#else
	slot_back = list(/obj/item/storage/backpack/security)
	slot_belt = list(/obj/item/device/pda2/hos)
	slot_poc1 = list(/obj/item/storage/security_pouch) //replaces sec starter kit
	slot_poc2 = list(/obj/item/requisition_token/security)
	slot_jump = list(/obj/item/clothing/under/rank/head_of_security)
	slot_suit = list(/obj/item/clothing/suit/armor/vest)
	slot_foot = list(/obj/item/clothing/shoes/swat)
	slot_head = list(/obj/item/clothing/head/hos_hat)
	slot_ears = list(/obj/item/device/radio/headset/command/hos)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses/sechud)
#endif

	New()
		..()
		src.access = get_access("Head of Security")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_drinker")
		M.traitHolder.addTrait("training_security")

	derelict
		name = null//"NT-SO Special Operative"
		limit = 0
		slot_suit = list(/obj/item/clothing/suit/armor/NT)
		slot_jump = list(/obj/item/clothing/under/misc/turds)
		slot_head = list(/obj/item/clothing/head/NTberet)
		slot_belt = list(/obj/item/tank/emergency_oxygen/extended)
		slot_mask = list(/obj/item/clothing/mask/gas)
		slot_glov = list(/obj/item/clothing/gloves/latex)
		slot_back = list(/obj/item/storage/backpack/NT)
		slot_eyes = list(/obj/item/clothing/glasses/thermal)
		items_in_backpack = list(/obj/item/crowbar,/obj/item/device/light/flashlight,/obj/item/breaching_charge,/obj/item/breaching_charge,/obj/item/gun/energy/plasma_gun)

		special_setup(var/mob/living/carbon/human/M)
			..()
			if (!M)
				return
			M.show_text("<b>Something has gone terribly wrong here! Search for survivors and escape together.</b>", "blue")

/datum/job/command/chief_engineer
	name = "Chief Engineer"
	limit = 1
	wages = PAY_IMPORTANT
	cant_spawn_as_rev = 1
	announce_on_join = 1
	allow_spy_theft = 0
	wiki_link = "https://wiki.ss13.co/Chief_Engineer"

	slot_back = list(/obj/item/storage/backpack/engineering)
	slot_belt = list(/obj/item/device/pda2/chiefengineer)
	slot_glov = list(/obj/item/clothing/gloves/yellow)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_head = list(/obj/item/clothing/head/helmet/hardhat/chief_engineer)
	slot_eyes = list(/obj/item/clothing/glasses/toggleable/meson)
	slot_jump = list(/obj/item/clothing/under/rank/chief_engineer)
	slot_ears = list(/obj/item/device/radio/headset/command/ce)
	slot_poc1 = list(/obj/item/paper/book/from_file/pocketguide/engineering)
	items_in_backpack = list(/obj/item/device/flash, /obj/item/rcd_ammo/medium)

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_engineer")

	New()
		..()
		src.access = get_access("Chief Engineer")
		return

	derelict
		name = null//"Salvage Chief"
		limit = 0
		slot_suit = list(/obj/item/clothing/suit/space/industrial)
		slot_foot = list(/obj/item/clothing/shoes/magnetic)
		slot_head = list(/obj/item/clothing/head/helmet/space/industrial)
		slot_belt = list(/obj/item/tank/emergency_oxygen)
		slot_mask = list(/obj/item/clothing/mask/gas)
		slot_eyes = list(/obj/item/clothing/glasses/thermal) // mesons look fuckin weird in the dark
		items_in_backpack = list(/obj/item/crowbar,/obj/item/rcd,/obj/item/rcd_ammo,/obj/item/rcd_ammo,/obj/item/device/light/flashlight,/obj/item/cell/cerenkite)

		special_setup(var/mob/living/carbon/human/M)
			..()
			if (!M)
				return
			M.show_text("<b>Something has gone terribly wrong here! Search for survivors and escape together.</b>", "blue")

/datum/job/command/research_director
	name = "Research Director"
	limit = 1
	wages = PAY_IMPORTANT
	allow_spy_theft = 0
	cant_spawn_as_rev = 1
	announce_on_join = 1
	wiki_link = "https://wiki.ss13.co/Research_Director"

	slot_back = list(/obj/item/storage/backpack/research)
	slot_belt = list(/obj/item/device/pda2/research_director)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_jump = list(/obj/item/clothing/under/rank/research_director)
	slot_suit = list(/obj/item/clothing/suit/labcoat/research_director)
	slot_rhan = list(/obj/item/clipboard/with_pen)
	slot_eyes = list(/obj/item/clothing/glasses/spectro)
	slot_ears = list(/obj/item/device/radio/headset/command/rd)
	items_in_backpack = list(/obj/item/device/flash)

	New()
		..()
		src.access = get_access("Research Director")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return

		for_by_tcl(heisenbee, /obj/critter/domestic_bee/heisenbee)
			if (!heisenbee.beeMom)
				heisenbee.beeMom = M
				heisenbee.beeMomCkey = M.ckey

/datum/job/command/medical_director
	name = "Medical Director"
	limit = 1
	wages = PAY_IMPORTANT
	allow_spy_theft = 0
	cant_spawn_as_rev = 1
	announce_on_join = 1
	wiki_link = "https://wiki.ss13.co/Medical_Director"

	slot_back = list(/obj/item/storage/backpack/medic)
	slot_glov = list(/obj/item/clothing/gloves/latex)
	slot_belt = list(/obj/item/storage/belt/medical/prepared)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_jump = list(/obj/item/clothing/under/rank/medical_director)
	slot_suit = list(/obj/item/clothing/suit/labcoat/medical_director)
	slot_ears = list(/obj/item/device/radio/headset/command/md)
	slot_eyes = list(/obj/item/clothing/glasses/healthgoggles/upgraded)
	slot_poc1 = list(/obj/item/device/pda2/medical_director)
	items_in_backpack = list(/obj/item/device/flash)

	New()
		..()
		src.access = get_access("Medical Director")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_medical")

#ifdef MAP_OVERRIDE_MANTA
/datum/job/command/comm_officer
	name = "Communications Officer"
	limit = 1
	wages = PAY_IMPORTANT
	allow_spy_theft = 0
	cant_spawn_as_rev = 1
	announce_on_join = 1
	wiki_link = "https://wiki.ss13.co/Communications_Officer"

	slot_ears = list(/obj/item/device/radio/headset/command/comm_officer)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses)
	slot_jump = list(/obj/item/clothing/under/rank/comm_officer)
	slot_card = /obj/item/card/id/command
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_back = list(/obj/item/storage/backpack/withO2)
	slot_belt = list(/obj/item/device/pda2/heads)
	slot_poc1 = list(/obj/item/pen/fancy)
	slot_head = list(/obj/item/clothing/head/sea_captain/comm_officer_hat)
	items_in_backpack = list(/obj/item/device/camera_viewer/security, /obj/item/device/audio_log, /obj/item/device/flash)

	New()
		..()
		src.access = get_access("Communications Officer")
		return
#endif

// Security Jobs

ABSTRACT_TYPE(/datum/job/security)
/datum/job/security
	linkcolor = "#FF0000"
	slot_card = /obj/item/card/id/security
	receives_miranda = 1

/datum/job/security/security_officer
	name = "Security Officer"
#ifdef MAP_OVERRIDE_MANTA
	limit = 4
#else
	limit = 5
#endif
	wages = PAY_TRADESMAN
	allow_traitors = 0
	allow_spy_theft = 0
	can_join_gangs = FALSE
	cant_spawn_as_con = 1
	cant_spawn_as_rev = 1
	receives_implant = /obj/item/implant/health/security/anti_mindhack
	receives_disk = 1
	receives_security_disk = 1
	receives_badge = 1
	slot_back = list(/obj/item/storage/backpack/security)
	slot_belt = list(/obj/item/device/pda2/security)
	slot_jump = list(/obj/item/clothing/under/rank/security)
	slot_suit = list(/obj/item/clothing/suit/armor/vest)
	slot_head = list(/obj/item/clothing/head/helmet/hardhat/security)
	slot_foot = list(/obj/item/clothing/shoes/swat)
	slot_ears = list(/obj/item/device/radio/headset/security)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses/sechud)
	slot_poc1 = list(/obj/item/storage/security_pouch) //replaces sec starter kit
	slot_poc2 = list(/obj/item/requisition_token/security)
	rounds_needed_to_play = 30 //higher barrier of entry than before but now with a trainee job to get into the rythym of things to compensate
	wiki_link = "https://wiki.ss13.co/Security_Officer"

	New()
		..()
		src.access = get_access("Security Officer")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_security")

	assistant
		name = "Security Assistant"
		limit = 3
		cant_spawn_as_con = 1
		wages = PAY_UNTRAINED
		receives_implant = /obj/item/implant/health/security
		slot_back = list(/obj/item/storage/backpack/security)
		slot_jump = list(/obj/item/clothing/under/rank/security/assistant)
		slot_suit = list()
		slot_glov = list(/obj/item/clothing/gloves/fingerless)
		slot_head = list(/obj/item/clothing/head/red)
		slot_foot = list(/obj/item/clothing/shoes/brown)
		slot_poc1 = list(/obj/item/storage/security_pouch/assistant)
		slot_poc2 = list(/obj/item/requisition_token/security/assistant)
		items_in_backpack = list(/obj/item/paper/book/from_file/space_law)
		rounds_needed_to_play = 5
		wiki_link = "https://wiki.ss13.co/Security_Assistant"

		New()
			..()
			src.access = get_access("Security Assistant")
			return

	derelict
		//name = "NT-SO Officer"
		name = null
		limit = 0
		slot_suit = list(/obj/item/clothing/suit/armor/NT_alt)
		slot_jump = list(/obj/item/clothing/under/misc/turds)
		slot_head = list(/obj/item/clothing/head/helmet/swat)
		slot_glov = list(/obj/item/clothing/gloves/fingerless)
		slot_back = list(/obj/item/storage/backpack/NT)
		slot_belt = list(/obj/item/gun/energy/laser_gun)
		slot_eyes = list(/obj/item/clothing/glasses/sunglasses)
		items_in_backpack = list(/obj/item/crowbar,/obj/item/device/light/flashlight,/obj/item/baton,/obj/item/breaching_charge,/obj/item/breaching_charge)

		special_setup(var/mob/living/carbon/human/M)
			..()
			if (!M)
				return
			M.show_text("<b>Something has gone terribly wrong here! Search for survivors and escape together.</b>", "blue")

/datum/job/security/detective
	name = "Detective"
	limit = 1
	wages = PAY_TRADESMAN
	//allow_traitors = 0
	receives_badge = 1
	cant_spawn_as_rev = 1
	allow_antag_fallthrough = FALSE
	slot_back = list(/obj/item/storage/backpack)
	slot_belt = list(/obj/item/storage/belt/security/shoulder_holster)
	slot_poc1 = list(/obj/item/device/pda2/forensic)
	slot_jump = list(/obj/item/clothing/under/rank/det)
	slot_foot = list(/obj/item/clothing/shoes/detective)
	slot_head = list(/obj/item/clothing/head/det_hat)
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_suit = list(/obj/item/clothing/suit/det_suit)
	slot_ears = list(/obj/item/device/radio/headset/detective)
	items_in_backpack = list(/obj/item/clothing/glasses/vr,/obj/item/storage/box/detectivegun)
	map_can_autooverride = 0
	rounds_needed_to_play = 15 // Half of sec, please stop shooting people with lethals
	wiki_link = "https://wiki.ss13.co/Detective"

	New()
		..()
		src.access = get_access("Detective")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_drinker")

		if (M.traitHolder && !M.traitHolder.hasTrait("smoker"))
			items_in_backpack += list(/obj/item/device/light/zippo) //Smokers start with a trinket version

// Research Jobs

ABSTRACT_TYPE(/datum/job/research)
/datum/job/research
	linkcolor = "#9900FF"
	slot_card = /obj/item/card/id/research

/datum/job/research/geneticist
	name = "Geneticist"
	limit = 2
	wages = PAY_DOCTORATE
	slot_back = list(/obj/item/storage/backpack/genetics)
	slot_belt = list(/obj/item/device/pda2/genetics)
	slot_jump = list(/obj/item/clothing/under/rank/geneticist)
	slot_foot = list(/obj/item/clothing/shoes/white)
	slot_suit = list(/obj/item/clothing/suit/labcoat/genetics)
	slot_ears = list(/obj/item/device/radio/headset/medical)
	slot_poc1 = list(/obj/item/device/analyzer/genetic)
	wiki_link = "https://wiki.ss13.co/Geneticist"

	New()
		..()
		src.access = get_access("Geneticist")
		return


#ifdef CREATE_PATHOGENS
/datum/job/research/pathologist
#else
/datum/job/pathologist // pls no autogenerate list
#endif
	name = "Pathologist"
	#ifdef CREATE_PATHOGENS
	limit = 1
	#else
	limit = 0
	#endif
	wages = PAY_DOCTORATE
	slot_belt = list(/obj/item/device/pda2/genetics)
	slot_jump = list(/obj/item/clothing/under/rank/pathologist)
	slot_foot = list(/obj/item/clothing/shoes/white)
	slot_suit = list(/obj/item/clothing/suit/labcoat/pathology)
	#ifdef SCIENCE_PATHO_MAP
	slot_ears = list(/obj/item/device/radio/headset/research)
	#else
	slot_ears = list(/obj/item/device/radio/headset/medical)
	#endif

	New()
		..()
		src.access = get_access("Pathologist")
		return

/datum/job/research/roboticist
	name = "Roboticist"
	limit = 3
	wages = 200
	slot_back = list(/obj/item/storage/backpack/robotics)
	slot_belt = list(/obj/item/storage/belt/roboticist/prepared)
	slot_jump = list(/obj/item/clothing/under/rank/roboticist)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_suit = list(/obj/item/clothing/suit/labcoat/robotics)
	slot_glov = list(/obj/item/clothing/gloves/latex)
	slot_eyes = list(/obj/item/clothing/glasses/healthgoggles/upgraded)
	slot_ears = list(/obj/item/device/radio/headset/medical)
	slot_poc1 = list(/obj/item/device/pda2/medical/robotics)
	slot_poc2 = list(/obj/item/reagent_containers/mender/brute)
	wiki_link = "https://wiki.ss13.co/Roboticist"

	New()
		..()
		src.access = get_access("Roboticist")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_medical")

/datum/job/research/scientist
	name = "Scientist"
	limit = 5
	wages = PAY_DOCTORATE
	slot_back = list(/obj/item/storage/backpack/research)
	slot_belt = list(/obj/item/device/pda2/toxins)
	slot_jump = list(/obj/item/clothing/under/rank/scientist)
	slot_suit = list(/obj/item/clothing/suit/labcoat)
	slot_foot = list(/obj/item/clothing/shoes/white)
	slot_mask = list(/obj/item/clothing/mask/gas)
	slot_lhan = list(/obj/item/tank/air)
	slot_ears = list(/obj/item/device/radio/headset/research)
	slot_eyes = list(/obj/item/clothing/glasses/spectro)
	slot_poc1 = list(/obj/item/pen = 50, /obj/item/pen/fancy = 25, /obj/item/pen/red = 5, /obj/item/pen/pencil = 20)
	wiki_link = "https://wiki.ss13.co/Scientist"

	New()
		..()
		src.access = get_access("Scientist")
		return

/datum/job/research/medical_doctor
	name = "Medical Doctor"
	limit = 5
	wages = PAY_DOCTORATE
	slot_back = list(/obj/item/storage/backpack/medic)
	slot_glov = list(/obj/item/clothing/gloves/latex)
	slot_belt = list(/obj/item/storage/belt/medical/prepared)
	slot_jump = list(/obj/item/clothing/under/rank/medical)
	slot_suit = list(/obj/item/clothing/suit/labcoat/medical)
	slot_foot = list(/obj/item/clothing/shoes/red)
	slot_ears = list(/obj/item/device/radio/headset/medical)
	slot_eyes = list(/obj/item/clothing/glasses/healthgoggles/upgraded)
	slot_poc1 = list(/obj/item/device/pda2/medical)
	slot_poc2 = list(/obj/item/paper/book/from_file/pocketguide/medical)
	items_in_backpack = list(/obj/item/crowbar/blue) // cogwerks: giving medics a guaranteed air tank, stealing it from roboticists (those fucks)
	// 2018: guaranteed air tanks now spawn in boxes (depending on backpack type) to save room
	wiki_link = "https://wiki.ss13.co/Medical_Doctor"

	New()
		..()
		src.access = get_access("Medical Doctor")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_medical")

	derelict
		//name = "Salvage Medic"
		name = null
		limit = 0
		slot_suit = list(/obj/item/clothing/suit/armor/vest)
		slot_head = list(/obj/item/clothing/head/helmet/swat)
		slot_belt = list(/obj/item/tank/emergency_oxygen)
		slot_mask = list(/obj/item/clothing/mask/breath)
		slot_eyes = list(/obj/item/clothing/glasses/healthgoggles/upgraded)
		slot_glov = list(/obj/item/clothing/gloves/latex)
		items_in_backpack = list(/obj/item/crowbar,/obj/item/device/light/flashlight,/obj/item/storage/firstaid/regular,/obj/item/storage/firstaid/regular)

		special_setup(var/mob/living/carbon/human/M)
			..()
			if (!M) return
			M.show_text("<b>Something has gone terribly wrong here! Search for survivors and escape together.</b>", "blue")

// Engineering Jobs

ABSTRACT_TYPE(/datum/job/engineering)
/datum/job/engineering
	linkcolor = "#FF9900"
	slot_card = /obj/item/card/id/engineering

/datum/job/engineering/quartermaster
	name = "Quartermaster"
	limit = 3
	wages = PAY_TRADESMAN
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_jump = list(/obj/item/clothing/under/rank/cargo)
	slot_belt = list(/obj/item/device/pda2/quartermaster)
	slot_ears = list(/obj/item/device/radio/headset/shipping)
	slot_poc1 = list(/obj/item/paper/book/from_file/pocketguide/quartermaster)
	slot_poc2 = list(/obj/item/device/appraisal)
	wiki_link = "https://wiki.ss13.co/Quartermaster"

	New()
		..()
		src.access = get_access("Quartermaster")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_quartermaster")

/datum/job/engineering/miner
	name = "Miner"
	#ifdef UNDERWATER_MAP
	limit = 6
	#else
	limit = 5
	#endif
	wages = PAY_TRADESMAN
	slot_back = list(/obj/item/storage/backpack/engineering)
	slot_mask = list(/obj/item/clothing/mask/breath)
	slot_eyes = list(/obj/item/clothing/glasses/toggleable/meson)
	slot_belt = list(/obj/item/storage/belt/mining/prepared)
	slot_jump = list(/obj/item/clothing/under/rank/overalls)
	slot_foot = list(/obj/item/clothing/shoes/orange)
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_ears = list(/obj/item/device/radio/headset/miner)
	slot_poc1 = list(/obj/item/device/pda2/mining)
	#ifdef UNDERWATER_MAP
	slot_suit = list(/obj/item/clothing/suit/space/diving/engineering)
	slot_head = list(/obj/item/clothing/head/helmet/space/engineer/diving/engineering)
	items_in_backpack = list(/obj/item/paper/book/from_file/pocketguide/mining,
							/obj/item/clothing/shoes/flippers,
							/obj/item/item_box/glow_sticker)
	#else
	slot_suit = list(/obj/item/clothing/suit/space/engineer)
	slot_head = list(/obj/item/clothing/head/helmet/space/engineer)
	items_in_backpack = list(/obj/item/crowbar,
							/obj/item/paper/book/from_file/pocketguide/mining)
	#endif
	wiki_link = "https://wiki.ss13.co/Miner"

	New()
		..()
		src.access = get_access("Miner")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_miner")

/datum/job/engineering/engineer
	name = "Engineer"
	limit = 8
	wages = PAY_TRADESMAN
	slot_back = list(/obj/item/storage/backpack/engineering)
	slot_belt = list(/obj/item/storage/belt/utility/prepared)
	slot_jump = list(/obj/item/clothing/under/rank/engineer)
	slot_foot = list(/obj/item/clothing/shoes/orange)
	slot_lhan = list(/obj/item/storage/toolbox/mechanical/engineer_spawn)
	slot_glov = list(/obj/item/clothing/gloves/yellow)
	slot_poc1 = list(/obj/item/device/pda2/engine)
	slot_ears = list(/obj/item/device/radio/headset/engineer)
#ifdef MAP_OVERRIDE_OSHAN
	items_in_backpack = list(/obj/item/paper/book/from_file/pocketguide/engineering, /obj/item/clothing/shoes/stomp_boots)
#else
	items_in_backpack = list(/obj/item/paper/book/from_file/pocketguide/engineering, /obj/item/old_grenade/oxygen)
#endif
	wiki_link = "https://wiki.ss13.co/Engineer"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_engineer")

	New()
		..()
		src.access = get_access("Engineer")
		return

	derelict
		name = null//"Salvage Engineer"
		limit = 0
		slot_suit = list(/obj/item/clothing/suit/space/engineer)
		slot_head = list(/obj/item/clothing/head/helmet/welding)
		slot_belt = list(/obj/item/tank/emergency_oxygen)
		slot_mask = list(/obj/item/clothing/mask/breath)
		items_in_backpack = list(/obj/item/crowbar,/obj/item/device/light/flashlight,/obj/item/device/light/glowstick,/obj/item/gun/kinetic/flaregun,/obj/item/ammo/bullets/flare,/obj/item/cell/cerenkite)

		special_setup(var/mob/living/carbon/human/M)
			..()
			if (!M)
				return
			M.show_text("<b>Something has gone terribly wrong here! Search for survivors and escape together.</b>", "blue")

// Civilian Jobs

ABSTRACT_TYPE(/datum/job/civilian)
/datum/job/civilian
	linkcolor = "#0099FF"
	slot_card = /obj/item/card/id/civilian

/datum/job/civilian/chef
	name = "Chef"
	limit = 1
	wages = PAY_UNTRAINED
	slot_belt = list(/obj/item/device/pda2/chef)
	slot_jump = list(/obj/item/clothing/under/rank/chef)
	slot_foot = list(/obj/item/clothing/shoes/chef)
	slot_head = list(/obj/item/clothing/head/chefhat)
	slot_suit = list(/obj/item/clothing/suit/chef)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	items_in_backpack = list(/obj/item/kitchen/rollingpin, /obj/item/kitchen/utensil/knife/cleaver, /obj/item/bell/kitchen)
	wiki_link = "https://wiki.ss13.co/Chef"

	New()
		..()
		src.access = get_access("Chef")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_chef")

/datum/job/civilian/bartender
	name = "Bartender"
	alias_names = list("Barman")
	limit = 1
	wages = PAY_UNTRAINED
	slot_belt = list(/obj/item/device/pda2/bartender)
	slot_jump = list(/obj/item/clothing/under/rank/bartender)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_suit = list(/obj/item/clothing/suit/armor/vest)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	slot_poc1 = list(/obj/item/cloth/towel/bar)
	slot_poc2 = list(/obj/item/reagent_containers/food/drinks/cocktailshaker)
	items_in_backpack = list(/obj/item/gun/kinetic/sawnoff, /obj/item/ammo/bullets/abg, /obj/item/paper/book/from_file/pocketguide/bartending)
	wiki_link = "https://wiki.ss13.co/Bartender"

	New()
		..()
		src.access = get_access("Bartender")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_drinker")

/datum/job/civilian/botanist
	name = "Botanist"
	#ifdef MAP_OVERRIDE_DONUT3
	limit = 7
	#else
	limit = 5
	#endif
	wages = PAY_TRADESMAN
	slot_belt = list(/obj/item/device/pda2/botanist)
	slot_jump = list(/obj/item/clothing/under/rank/hydroponics)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_poc1 = list(/obj/item/paper/botany_guide)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	wiki_link = "https://wiki.ss13.co/Botanist"

	faction = FACTION_BOTANY

	New()
		..()
		src.access = get_access("Botanist")
		return

/datum/job/civilian/rancher
	name = "Rancher"
	limit = 1
	wages = PAY_TRADESMAN
	slot_belt = list(/obj/item/storage/belt/rancher/prepared)
	slot_jump = list(/obj/item/clothing/under/rank/rancher)
	slot_head = list(/obj/item/clothing/head/cowboy)
	slot_foot = list(/obj/item/clothing/shoes/westboot/brown/rancher)
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_poc1 = list(/obj/item/paper/ranch_guide)
	slot_poc2 = list(/obj/item/device/pda2/botanist)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	items_in_backpack = list(/obj/item/device/camera_viewer/ranch,/obj/item/storage/box/knitting)
	wiki_link = "https://wiki.ss13.co/Rancher"

	New()
		..()
		src.access = get_access("Rancher")
		return

/datum/job/civilian/janitor
	name = "Janitor"
	limit = 3
	wages = PAY_TRADESMAN
	slot_belt = list(/obj/item/storage/fanny/janny)
	slot_jump = list(/obj/item/clothing/under/rank/janitor)
	slot_foot = list(/obj/item/clothing/shoes/galoshes)
	slot_glov = list(/obj/item/clothing/gloves/long)
	slot_rhan = list(/obj/item/mop)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	slot_poc1 = list(/obj/item/device/pda2/janitor)
	items_in_backpack = list(/obj/item/reagent_containers/glass/bucket)
	wiki_link = "https://wiki.ss13.co/Janitor"

	New()
		..()
		src.access = get_access("Janitor")
		return

/datum/job/civilian/chaplain
	name = "Chaplain"
	limit = 1
	wages = PAY_UNTRAINED
	slot_jump = list(/obj/item/clothing/under/rank/chaplain)
	slot_belt = list(/obj/item/device/pda2/chaplain)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	slot_lhan = list(/obj/item/bible/loaded)
	wiki_link = "https://wiki.ss13.co/Chaplain"

	New()
		..()
		src.access = get_access("Chaplain")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_chaplain")
		OTHER_START_TRACKING_CAT(M, TR_CAT_CHAPLAINS)
		if (prob(15))
			M.see_invisible = INVIS_GHOST

/datum/job/civilian/staff_assistant
	name = "Staff Assistant"
	wages = PAY_UNTRAINED
	no_jobban_from_this_job = 1
	low_priority_job = 1
	cant_allocate_unwanted = 1
	map_can_autooverride = 0
	slot_jump = list(/obj/item/clothing/under/rank/assistant)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	wiki_link = "https://wiki.ss13.co/Staff_Assistant"

	New()
		..()
		src.access = get_access("Staff Assistant")
		return

/datum/job/civilian/clown
	name = "Clown"
	limit = 1
	wages = PAY_DUMBCLOWN
	linkcolor = "#FF99FF"
	slot_back = list()
	slot_belt = list(/obj/item/storage/fanny/funny)
	slot_mask = list(/obj/item/clothing/mask/clown_hat)
	slot_jump = list(/obj/item/clothing/under/misc/clown)
	slot_foot = list(/obj/item/clothing/shoes/clown_shoes)
	slot_lhan = list(/obj/item/instrument/bikehorn)
	slot_poc1 = list(/obj/item/device/pda2/clown)
	slot_poc2 = list(/obj/item/reagent_containers/food/snacks/plant/banana)
	slot_card = /obj/item/card/id/clown
	slot_ears = list(/obj/item/device/radio/headset/clown)
	items_in_belt = list(/obj/item/cloth/towel/clown)
	change_name_on_spawn = 1
	wiki_link = "https://wiki.ss13.co/Clown"

	faction = FACTION_CLOWN

	New()
		..()
		src.access = get_access("Clown")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return


		M.traitHolder.addTrait("training_clown")

// AI and Cyborgs

/datum/job/civilian/AI
	name = "AI"
	linkcolor = "#999999"
	limit = 1
	no_late_join = 1
	high_priority_job = 1
	allow_traitors = 0
	cant_spawn_as_rev = 1
	slot_ears = list()
	slot_card = null
	slot_back = list()
	slot_belt = list()
	items_in_backpack = list()
	uses_character_profile = FALSE
	wiki_link = "https://wiki.ss13.co/Artificial_Intelligence"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		return M.AIize()

/datum/job/civilian/cyborg
	name = "Cyborg"
	linkcolor = "#999999"
	limit = 8
	no_late_join = 1
	allow_traitors = 0
	cant_spawn_as_rev = 1
	slot_ears = list()
	slot_card = null
	slot_back = list()
	slot_belt = list()
	items_in_backpack = list()
	uses_character_profile = FALSE
	wiki_link = "https://wiki.ss13.co/Cyborg"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		return M.Robotize_MK2()

// Special Cases

/datum/job/special/station_builder
	// Used for Construction game mode, where you build the station
	name = "Station Builder"
	allow_traitors = 0
	cant_spawn_as_rev = 1
	limit = 0
	wages = PAY_TRADESMAN
	slot_belt = list(/obj/item/storage/belt/utility/prepared)
	slot_jump = list(/obj/item/clothing/under/rank/engineer)
	slot_foot = list(/obj/item/clothing/shoes/magnetic)
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_ears = list(/obj/item/device/radio/headset/engineer)
	slot_rhan = list(/obj/item/tank/jetpack)
	slot_eyes = list(/obj/item/clothing/glasses/construction)
	slot_poc1 = list(/obj/item/currency/spacecash/fivehundred)
	slot_poc2 = list(/obj/item/room_planner)
	slot_suit = list(/obj/item/clothing/suit/space/engineer)
	slot_head = list(/obj/item/clothing/head/helmet/space/engineer)
	slot_mask = list(/obj/item/clothing/mask/breath)
	wiki_link = "https://wiki.ss13.co/Construction_Game_Mode" // ?

	items_in_backpack = list(/obj/item/rcd/construction, /obj/item/rcd_ammo/big, /obj/item/rcd_ammo/big, /obj/item/material_shaper,/obj/item/room_marker)

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_engineer")

	New()
		..()
		src.access = get_access("Construction Worker")
		return

/datum/job/special/hairdresser
	name = "Hairdresser"
	wages = PAY_UNTRAINED
	limit = 0
	slot_jump = list(/obj/item/clothing/under/misc/barber)
	slot_head = list(/obj/item/clothing/head/boater_hat)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_poc1 = list(/obj/item/scissors)
	slot_poc2 = list(/obj/item/razor_blade)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	wiki_link = "https://wiki.ss13.co/Barber"

	New()
		..()
		src.access = get_access("Barber")
		return

/datum/job/special/mime
	name = "Mime"
	limit = 1
	wages = PAY_DUMBCLOWN*2 // lol okay whatever
	slot_belt = list(/obj/item/device/pda2)
	slot_head = list(/obj/item/clothing/head/mime_bowler)
	slot_mask = list(/obj/item/clothing/mask/mime)
	slot_jump = list(/obj/item/clothing/under/misc/mime/alt)
	slot_suit = list(/obj/item/clothing/suit/scarf)
	slot_glov = list(/obj/item/clothing/gloves/latex)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_poc1 = list(/obj/item/pen/crayon/white)
	slot_poc2 = list(/obj/item/paper)
	items_in_backpack = list(/obj/item/baguette)
	change_name_on_spawn = 1
	wiki_link = "https://wiki.ss13.co/Mime"

	New()
		..()
		src.access = get_access("Mime")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_mime")

/datum/job/special/attorney
	name = "Attorney"
	linkcolor = "#FF0000"
	wages = PAY_DOCTORATE
	limit = 0
	receives_badge = 1
	slot_jump = list(/obj/item/clothing/under/misc/lawyer)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_lhan = list(/obj/item/storage/briefcase)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	wiki_link = "https://wiki.ss13.co/Lawyer"

	New()
		..()
		src.access = get_access("Lawyer")
		return

/datum/job/special/attorney/judge
	name = "Judge"
	limit = 0

	New()
		..()
		src.access = get_all_accesses()
		return

/datum/job/special/vice_officer
	name = "Vice Officer"
	linkcolor = "#FF0000"
	limit = 0
	wages = PAY_TRADESMAN
	allow_traitors = 0
	can_join_gangs = FALSE
	cant_spawn_as_con = 1
	cant_spawn_as_rev = 1
	receives_badge = 1
	receives_miranda = 1
	slot_back = list(/obj/item/storage/backpack/withO2)
	slot_belt = list(/obj/item/device/pda2/security)
	slot_jump = list(/obj/item/clothing/under/misc/vice)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_ears = list( /obj/item/device/radio/headset/security)
	slot_poc1 = list(/obj/item/storage/security_pouch) //replaces sec starter kit
	slot_poc2 = list(/obj/item/requisition_token/security)
	wiki_link = "https://wiki.ss13.co/Part-Time_Vice_Officer"

	New()
		..()
		src.access = get_access("Vice Officer")
		return

/datum/job/special/forensic_technician
	name = "Forensic Technician"
	linkcolor = "#FF0000"
	limit = 0
	wages = PAY_TRADESMAN
	cant_spawn_as_rev = 1
	slot_belt = list(/obj/item/device/pda2/security)
	slot_jump = list(/obj/item/clothing/under/color/darkred)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_glov = list(/obj/item/clothing/gloves/latex)
	slot_ears = list(/obj/item/device/radio/headset/security)
	slot_poc1 = list(/obj/item/device/detective_scanner)
	items_in_backpack = list(/obj/item/tank/emergency_oxygen)
	// missing wiki link

	New()
		..()
		src.access = get_access("Forensic Technician")
		return

/datum/job/special/toxins_researcher
	name = "Toxins Researcher"
	linkcolor = "#9900FF"
	limit = 0
	wages = PAY_DOCTORATE
	slot_belt = list(/obj/item/device/pda2/toxins)
	slot_jump = list(/obj/item/clothing/under/rank/scientist)
	slot_foot = list(/obj/item/clothing/shoes/white)
	slot_mask = list(/obj/item/clothing/mask/gas)
	slot_lhan = list(/obj/item/tank/air)
	slot_ears = list(/obj/item/device/radio/headset/research)
	// missing wiki link

	New()
		..()
		src.access = get_access("Toxins Researcher")
		return

/datum/job/special/chemist
	name = "Chemist"
	linkcolor = "#9900FF"
	limit = 0
	wages = PAY_DOCTORATE
	slot_belt = list(/obj/item/device/pda2/toxins)
	slot_jump = list(/obj/item/clothing/under/rank/scientist)
	slot_foot = list(/obj/item/clothing/shoes/white)
	slot_ears = list(/obj/item/device/radio/headset/research)
	wiki_link = "https://wiki.ss13.co/Chemist"

	New()
		..()
		src.access = get_access("Chemist")
		return

/datum/job/special/research_assistant
	name = "Research Assistant"
	linkcolor = "#9900FF"
	limit = 2
	wages = PAY_UNTRAINED
	low_priority_job = 1
	slot_jump = list(/obj/item/clothing/under/color/white)
	slot_foot = list(/obj/item/clothing/shoes/white)
	slot_belt = list(/obj/item/device/pda2/toxins)
	slot_ears = list(/obj/item/device/radio/headset/research)
	wiki_link = "https://wiki.ss13.co/Research_Assistant"

	New()
		..()
		src.access = get_access("Research Assistant")
		return

/datum/job/special/medical_assistant
	name = "Medical Assistant"
	linkcolor = "#9900FF"
	limit = 2
	wages = PAY_UNTRAINED
	low_priority_job = 1
	slot_jump = list(/obj/item/clothing/under/scrub = 30,/obj/item/clothing/under/scrub/teal = 14,/obj/item/clothing/under/scrub/blue = 14,/obj/item/clothing/under/scrub/purple = 14,/obj/item/clothing/under/scrub/orange = 14,/obj/item/clothing/under/scrub/pink = 14)
	slot_foot = list(/obj/item/clothing/shoes/red)
	slot_ears = list(/obj/item/device/radio/headset/medical)
	slot_belt = list(/obj/item/device/pda2/medical)
	wiki_link = "https://wiki.ss13.co/Medical_Assistant"

	New()
		..()
		src.access = get_access("Medical Assistant")
		return

/datum/job/special/atmospheric_technician
	name = "Atmospherish Technician"
	linkcolor = "#FF9900"
	limit = 0
	wages = PAY_TRADESMAN
	slot_belt = list(/obj/item/device/pda2/atmos)
	slot_eyes = list(/obj/item/clothing/glasses/toggleable/atmos)
	slot_jump = list(/obj/item/clothing/under/misc/atmospheric_technician)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_lhan = list(/obj/item/storage/toolbox/mechanical)
	slot_poc1 = list(/obj/item/device/analyzer/atmospheric)
	slot_ears = list(/obj/item/device/radio/headset/engineer)
	items_in_backpack = list(/obj/item/tank/mini_oxygen,/obj/item/crowbar)
	wiki_link = "https://wiki.ss13.co/Atmospheric_Technician"

	New()
		..()
		src.access = get_access("Atmospheric Technician")
		return

/datum/job/special/tech_assistant
	name = "Technical Assistant"
	linkcolor = "#FF9900"
	limit = 2
	wages = PAY_UNTRAINED
	low_priority_job = 1
	slot_jump = list(/obj/item/clothing/under/color/yellow)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_ears = list(/obj/item/device/radio/headset/engineer)
	slot_belt = list(/obj/item/device/pda2/technical_assistant)
	wiki_link = "https://wiki.ss13.co/Technical_Assistant"

	New()
		..()
		src.access = get_access("Technical Assistant")
		return


/datum/job/special/space_cowboy
	name = "Space Cowboy"
	linkcolor = "#FF99FF"
	limit = 0
	wages = PAY_UNTRAINED
	slot_jump = list(/obj/item/clothing/under/rank/det)
	slot_belt = list(/obj/item/gun/kinetic/single_action/colt_saa)
	slot_head = list(/obj/item/clothing/head/cowboy)
	slot_mask = list(/obj/item/clothing/mask/cigarette/random)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses)
	slot_foot = list(/obj/item/clothing/shoes/cowboy)
	slot_poc1 = list(/obj/item/cigpacket/random)
	slot_poc2 = list(/obj/item/device/light/zippo/gold)
	slot_lhan = list(/obj/item/whip)
	slot_back = list(/obj/item/storage/backpack/satchel)
	// missing wiki link

	New()
		..()
		src.access = get_access("Space Cowboy")
		return

// randomizd gimmick jobs

/datum/job/special/random
	limit = 0
	//requires_whitelist = 1
	name = "Hollywood Actor"
	wages = PAY_UNTRAINED
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_jump = list(/obj/item/clothing/under/suit/purple)
	//change_name_on_spawn = 1
	wiki_link = "https://wiki.ss13.co/Jobs#Gimmick_Jobs" // fallback for those without their own page

	New()
		..()
		if (prob(40))
			limit = 1
		if (src.alt_names.len)
			name = pick(src.alt_names)

/datum/job/special/random/medical_specialist
	name = "Medical Specialist"
	linkcolor = "#9900FF"
	wages = PAY_IMPORTANT
	slot_card = /obj/item/card/id/research
	slot_belt = list(/obj/item/storage/belt/medical/prepared)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_back = list(/obj/item/storage/backpack/medic)
	slot_jump = list(/obj/item/clothing/under/scrub/maroon)
	slot_suit = list(/obj/item/clothing/suit/apron/surgeon)
	slot_head = list(/obj/item/clothing/head/bouffant)
	slot_ears = list(/obj/item/device/radio/headset/medical)
	slot_rhan = list(/obj/item/storage/firstaid/docbag)
	slot_poc1 = list(/obj/item/device/pda2/medical_director)
	alt_names = list("Neurological Specialist", "Ophthalmic Specialist", "Thoracic Specialist", "Orthopaedic Specialist", "Maxillofacial Specialist",
	  "Vascular Specialist", "Anaesthesiologist", "Acupuncturist", "Medical Director's Assistant")
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

	New()
		..()
		src.access = get_access("Medical Specialist")

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_medical")
		M.traitHolder.addTrait("training_partysurgeon")

/datum/job/special/random/vip
	name = "VIP"
	wages = PAY_EXECUTIVE
	linkcolor = "#FF0000"
	slot_jump = list(/obj/item/clothing/under/suit/black)
	slot_head = list(/obj/item/clothing/head/that)
	slot_eyes = list(/obj/item/clothing/glasses/monocle)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_lhan = list(/obj/item/storage/secure/sbriefcase)
	items_in_backpack = list(/obj/item/baton/cane)
	alt_names = list("Senator", "President", "CEO", "Board Member", "Mayor", "Vice-President", "Governor")
	wiki_link = "https://wiki.ss13.co/VIP"

	New()
		..()
		src.access = get_access("VIP")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return

		var/obj/item/storage/secure/sbriefcase/B = M.find_type_in_hand(/obj/item/storage/secure/sbriefcase)
		if (B && istype(B))
			for (var/i = 1 to 2)
				B.storage.add_contents(new /obj/item/stamped_bullion(B))

		return

/datum/job/special/random/inspector
	name = "Inspector"
	wages = PAY_IMPORTANT
	receives_miranda = 1
	cant_spawn_as_rev = 1
	receives_badge = 1
	slot_back = list(/obj/item/storage/backpack)
	slot_belt = list(/obj/item/device/pda2/heads)
	slot_jump = list(/obj/item/clothing/under/misc/lawyer/black) // so they can slam tables
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_ears = list(/obj/item/device/radio/headset/command)
	slot_head = list(/obj/item/clothing/head/NTberet)
	slot_suit = list(/obj/item/clothing/suit/armor/NT)
	slot_eyes = list(/obj/item/clothing/glasses/regular)
	slot_lhan = list(/obj/item/storage/briefcase)
	slot_rhan = list(/obj/item/device/ticket_writer)
	items_in_backpack = list(/obj/item/device/flash)
	wiki_link = "https://wiki.ss13.co/Inspector"

	New()
		..()
		src.access = get_access("Inspector")
		return

	proc/inspector_miranda()
		return "You have been found to be in breach of Nanotrasen corporate regulation [rand(1,100)][pick(uppercase_letters)]. You are allowed a grace period of 5 minutes to correct this infringement before you may be subjected to disciplinary action including but not limited to: strongly worded tickets, reduction in pay, and being buried in paperwork for the next [rand(10,20)] standard shifts."

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return

		var/obj/item/storage/briefcase/B = M.find_type_in_hand(/obj/item/storage/briefcase)
		if (B && istype(B))
			B.storage.add_contents(new /obj/item/instrument/whistle(B))
			var/obj/item/clipboard/with_pen/inspector/clipboard = new /obj/item/clipboard/with_pen/inspector(B)
			B.storage.add_contents(clipboard)
			clipboard.set_owner(M)
		M.mind?.set_miranda(PROC_REF(inspector_miranda))
		return

/datum/job/special/random/director
	name = "Regional Director"
	receives_miranda = 1
	cant_spawn_as_rev = 1
	wages = PAY_EXECUTIVE

	slot_back = list(/obj/item/storage/backpack)
	slot_belt = list(/obj/item/device/pda2/heads)
	slot_jump = list(/obj/item/clothing/under/misc/NT)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_ears = list(/obj/item/device/radio/headset/command)
	slot_head = list(/obj/item/clothing/head/NTberet)
	slot_suit = list(/obj/item/clothing/suit/wcoat)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses)
	slot_lhan = list(/obj/item/clipboard/with_pen)
	items_in_backpack = list(/obj/item/device/flash)
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

	New()
		..()
		src.access = get_all_accesses()

/datum/job/special/random/diplomat
	name = "Diplomat"
	wages = PAY_DUMBCLOWN
	slot_lhan = list(/obj/item/storage/briefcase)
	slot_jump = list(/obj/item/clothing/under/misc/lawyer)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	alt_names = list("Diplomat", "Ambassador")
	cant_spawn_as_rev = 1
	change_name_on_spawn = 1
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

	New()
		..()
		src.access = get_access("Diplomat")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		var/morph = pick(/datum/mutantrace/lizard,/datum/mutantrace/skeleton,/datum/mutantrace/ithillid,/datum/mutantrace/martian,/datum/mutantrace/amphibian,/datum/mutantrace/blob,/datum/mutantrace/cow)
		M.set_mutantrace(morph)

/datum/job/special/random/testsubject
	name = "Test Subject"
	wages = PAY_DUMBCLOWN
	slot_jump = list(/obj/item/clothing/under/shorts)
	slot_mask = list(/obj/item/clothing/mask/monkey_translator)
	change_name_on_spawn = 1
	starting_mutantrace = /datum/mutantrace/monkey
	wiki_link = "https://wiki.ss13.co/Monkey"

/datum/job/special/random/union
	name = "Union Rep"
	wages = PAY_TRADESMAN
	slot_jump = list(/obj/item/clothing/under/misc/lawyer)
	slot_lhan = list(/obj/item/storage/briefcase)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	alt_names = list("Assistants Union Rep", "Cyborgs Union Rep", "Union Rep", "Security Union Rep", "Doctors Union Rep", "Engineers Union Rep", "Miners Union Rep")
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return

		var/obj/item/storage/briefcase/B = M.find_type_in_hand(/obj/item/storage/briefcase)
		if (B && istype(B))
			B.storage.add_contents(new /obj/item/clipboard/with_pen(B))

		return

/datum/job/special/random/salesman
	name = "Salesman"
	wages = PAY_TRADESMAN
	slot_suit = list(/obj/item/clothing/suit/merchant)
	slot_jump = list(/obj/item/clothing/under/gimmick/merchant)
	slot_head = list(/obj/item/clothing/head/merchant_hat)
	slot_lhan = list(/obj/item/storage/briefcase)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	alt_names = list("Salesman", "Merchant")
	change_name_on_spawn = 1
	wiki_link = "https://wiki.ss13.co/Salesman"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return

		if(prob(33))
			var/morph = pick(/datum/mutantrace/lizard,/datum/mutantrace/skeleton,/datum/mutantrace/ithillid,/datum/mutantrace/martian,/datum/mutantrace/amphibian)
			M.set_mutantrace(morph)

		var/obj/item/storage/briefcase/B = M.find_type_in_hand(/obj/item/storage/briefcase)
		if (B && istype(B))
			for (var/i = 1 to 2)
				B.storage.add_contents(new /obj/item/stamped_bullion(B))

		return

/datum/job/special/random/coach
	name = "Coach"
	wages = PAY_UNTRAINED
	slot_jump = list(/obj/item/clothing/under/jersey)
	slot_suit = list(/obj/item/clothing/suit/armor/vest/macho)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses)
	slot_foot = list(/obj/item/clothing/shoes/white)
	slot_poc1 = list(/obj/item/instrument/whistle)
	slot_glov = list(/obj/item/clothing/gloves/boxing)
	items_in_backpack = list(/obj/item/football,/obj/item/football,/obj/item/basketball,/obj/item/basketball)
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

/datum/job/special/random/journalist
	name = "Journalist"
	wages = PAY_UNTRAINED
	slot_jump = list(/obj/item/clothing/under/suit/red)
	slot_head = list(/obj/item/clothing/head/fedora)
	slot_lhan = list(/obj/item/storage/briefcase)
	slot_poc1 = list(/obj/item/camera)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	items_in_backpack = list(/obj/item/camera_film/large)
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return

		var/obj/item/storage/briefcase/B = M.find_type_in_hand(/obj/item/storage/briefcase)
		if (B && istype(B))
			B.storage.add_contents(new /obj/item/device/camera_viewer/public(B))
			B.storage.add_contents(new /obj/item/clothing/head/helmet/camera(B))
			B.storage.add_contents(new /obj/item/device/audio_log(B))
			B.storage.add_contents(new /obj/item/clipboard/with_pen(B))

		return

/datum/job/special/random/beekeeper
	name = "Apiculturist"
	wages = PAY_TRADESMAN
	slot_jump = list(/obj/item/clothing/under/rank/beekeeper)
	slot_suit = list(/obj/item/clothing/suit/hazard/beekeeper)
	slot_head = list(/obj/item/clothing/head/bio_hood/beekeeper)
	slot_poc1 = list(/obj/item/reagent_containers/food/snacks/beefood)
	slot_poc2 = list(/obj/item/paper/book/from_file/bee_book)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_belt = list(/obj/item/device/pda2/botanist)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	items_in_backpack = list(/obj/item/bee_egg_carton, /obj/item/bee_egg_carton, /obj/item/bee_egg_carton, /obj/item/reagent_containers/food/snacks/beefood, /obj/item/reagent_containers/food/snacks/beefood)
	alt_names = list("Apiculturist", "Apiarist")
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

	faction = FACTION_BOTANY

	New()
		..()
		src.access = get_access("Apiculturist")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		if (prob(15))
			var/obj/critter/domestic_bee/bee = new(get_turf(M))
			bee.beeMom = M
			bee.beeMomCkey = M.ckey
			bee.name = pick_string("bee_names.txt", "beename")
			bee.name = replacetext(bee.name, "larva", "bee")

		M.bioHolder.AddEffect("bee", magical=1) //They're one with the bees!


/datum/job/special/random/angler
	name = "Angler"
	wages = PAY_TRADESMAN
	slot_jump = list(/obj/item/clothing/under/rank/angler)
	slot_head = list(/obj/item/clothing/head/black)
	slot_foot = list(/obj/item/clothing/shoes/galoshes/waders)
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	items_in_backpack = list(/obj/item/fishing_rod/basic)
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

	New()
		..()
		src.access = get_access("Rancher")
		return

/datum/job/special/random/souschef
	name = "Sous-Chef"
	wages = PAY_UNTRAINED
	slot_belt = list(/obj/item/device/pda2/chef)
	slot_jump = list(/obj/item/clothing/under/misc/souschef)
	slot_foot = list(/obj/item/clothing/shoes/chef)
	slot_head = list(/obj/item/clothing/head/souschefhat)
	slot_suit = list(/obj/item/clothing/suit/apron)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	// missing wiki link, should we link to chef instead?

	New()
		..()
		src.access = get_access("Sous-Chef")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_chef")

/datum/job/special/random/waiter
	name = "Waiter"
	wages = PAY_UNTRAINED
	slot_jump = list(/obj/item/clothing/under/rank/bartender)
	slot_suit = list(/obj/item/clothing/suit/wcoat)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	slot_lhan = list(/obj/item/plate/tray)
	slot_poc1 = list(/obj/item/cloth/towel/white)
	items_in_backpack = list(/obj/item/storage/box/glassbox,/obj/item/storage/box/cutlery)
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

	New()
		..()
		src.access = get_access("Waiter")
		return

/datum/job/special/random/pharmacist
	name = "Pharmacist"
	wages = PAY_DOCTORATE
	slot_card = /obj/item/card/id/research
	slot_belt = list(/obj/item/device/pda2/medical)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_jump = list(/obj/item/clothing/under/shirt_pants)
	slot_suit = list(/obj/item/clothing/suit/labcoat)
	slot_ears = list(/obj/item/device/radio/headset/medical)
	items_in_backpack = list(/obj/item/storage/box/beakerbox, /obj/item/storage/pill_bottle/cyberpunk)
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

	New()
		..()
		src.access = get_access("Pharmacist")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_medical")

/datum/job/special/random/radioshowhost
	name = "Radio Show Host"
	wages = PAY_TRADESMAN
#ifdef MAP_OVERRIDE_MANTA
	limit = 0
	special_spawn_location = null
#elif defined(MAP_OVERRIDE_OSHAN)
	limit = 1
	special_spawn_location = null
#elif defined(MAP_OVERRIDE_NADIR)
	limit = 1
	special_spawn_location = null
#else
	limit = 1
	special_spawn_location = LANDMARK_RADIO_SHOW_HOST
#endif
	slot_ears = list(/obj/item/device/radio/headset/command/radio_show_host)
	slot_eyes = list(/obj/item/clothing/glasses/regular)
	slot_jump = list(/obj/item/clothing/under/shirt_pants)
	slot_card = /obj/item/card/id/civilian
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_back = list(/obj/item/storage/backpack/satchel)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/reagent_containers/food/drinks/coffee)
	items_in_backpack = list(/obj/item/device/camera_viewer/security, /obj/item/device/audio_log, /obj/item/storage/box/record/radio/host)
	alt_names = list("Radio Show Host", "Talk Show Host")
	change_name_on_spawn = 1
	wiki_link = "https://wiki.ss13.co/Radio_Host"

	New()
		..()
		src.access = get_access("Radio Show Host")
		return

/datum/job/special/random/psychiatrist
	name = "Psychiatrist"
	wages = PAY_DOCTORATE
	slot_eyes = list(/obj/item/clothing/glasses/regular)
	slot_card = /obj/item/card/id/research
	slot_belt = list(/obj/item/device/pda2/medical)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_jump = list(/obj/item/clothing/under/shirt_pants)
	slot_suit = list(/obj/item/clothing/suit/labcoat)
	slot_ears = list(/obj/item/device/radio/headset/medical)
	slot_poc1 = list(/obj/item/reagent_containers/food/drinks/tea)
	slot_poc2 = list(/obj/item/reagent_containers/food/drinks/bottle/gin)
	items_in_backpack = list(/obj/item/luggable_computer/personal, /obj/item/clipboard/with_pen, /obj/item/paper_bin, /obj/item/stamp)
	alt_names = list("Psychiatrist", "Psychologist", "Psychotherapist", "Therapist", "Counselor", "Life Coach") // All with slightly different connotations
	// missing wiki link, parent fallback to https://wiki.ss13.co/Jobs#Gimmick_Jobs

	New()
		..()
		src.access = get_access("Psychiatrist")
		return

/datum/job/special/random/artist
	name = "Artist"
	wages = PAY_UNTRAINED
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_jump = list(/obj/item/clothing/under/misc/casualjeansblue)
	slot_head = list(/obj/item/clothing/head/mime_beret)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	slot_poc1 = list(/obj/item/currency/spacecash/twenty)
	slot_poc2 = list(/obj/item/pen/pencil)
	slot_lhan = list(/obj/item/storage/toolbox/artistic)
	items_in_backpack = list(/obj/item/canvas, /obj/item/canvas, /obj/item/storage/box/crayon/basic ,/obj/item/paint_can/random)
	// missing wiki link, does not have a mention on https://wiki.ss13.co/Jobs

#ifdef HALLOWEEN
/*
 * Halloween jobs
 */
ABSTRACT_TYPE(/datum/job/special/halloween)
/datum/job/special/halloween
	linkcolor = "#FF7300"
	wiki_link = "https://wiki.ss13.co/Jobs#Spooktober_Jobs"

/datum/job/special/halloween/blue_clown
	name = "Blue Clown"
	wages = PAY_DUMBCLOWN
	limit = 1
	change_name_on_spawn = 1
	slot_mask = list(/obj/item/clothing/mask/clown_hat/blue)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_jump = list(/obj/item/clothing/under/misc/clown/blue)
	slot_card = /obj/item/card/id/clown
	slot_foot = list(/obj/item/clothing/shoes/clown_shoes/blue)
	slot_belt = list(/obj/item/storage/fanny/funny)
	slot_poc1 = list(/obj/item/bananapeel)
	slot_poc2 = list(/obj/item/device/pda2/clown)
	slot_lhan = list(/obj/item/instrument/bikehorn)

	faction = FACTION_CLOWN

	New()
		..()
		src.access = get_access("Clown")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return

		M.traitHolder.addTrait("training_clown")
		M.bioHolder.AddEffect("regenerator", magical=1)

/datum/job/special/halloween/candy_salesman
	name = "Candy Salesman"
	wages = PAY_UNTRAINED
	limit = 1
	slot_head = list(/obj/item/clothing/head/that/purple)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_jump = list(/obj/item/clothing/under/suit/purple)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/storage/pill_bottle/cyberpunk)
	slot_poc2 = list(/obj/item/storage/pill_bottle/catdrugs)
	items_in_backpack = list(/obj/item/storage/goodybag, /obj/item/kitchen/everyflavor_box, /obj/item/item_box/heartcandy, /obj/item/kitchen/peach_rings)

	New()
		..()
		src.access = get_access("Salesman")
		return

/datum/job/special/halloween/pumpkin_head
	name = "Pumpkin Head"
	wages = PAY_UNTRAINED
	limit = 1
	change_name_on_spawn = 1
	slot_head = list(/obj/item/clothing/head/pumpkin)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_jump = list(/obj/item/clothing/under/color/orange)
	slot_foot = list(/obj/item/clothing/shoes/orange)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/reagent_containers/food/snacks/candy/candy_corn)
	slot_poc2 = list(/obj/item/item_box/assorted/stickers/stickers_limited)

	New()
		..()
		src.access = get_access("Staff Assistant")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("quiet_voice", magical=1)

/datum/job/special/halloween/wanna_bee
	name = "WannaBEE"
	wages = PAY_UNTRAINED
	limit = 1

	slot_head = list(/obj/item/clothing/head/headband/bee)
	slot_suit = list(/obj/item/clothing/suit/bee)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_jump = list(/obj/item/clothing/under/rank/beekeeper)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/reagent_containers/food/snacks/ingredient/egg/bee)
	slot_poc2 = list(/obj/item/reagent_containers/food/snacks/ingredient/egg/bee/buddy)
	items_in_backpack = list(/obj/item/reagent_containers/food/snacks/b_cupcake, /obj/item/reagent_containers/food/snacks/ingredient/royal_jelly)

	New()
		..()
		src.access = get_access("Botanist")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("drunk_bee", magical=1)

/datum/job/special/halloween/dracula
	name = "Discount Dracula"
	wages = PAY_UNTRAINED
	limit = 1
	change_name_on_spawn = 1
	slot_head = list(/obj/item/clothing/head/that)
	slot_suit = list(/obj/item/clothing/suit/gimmick/vampire)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_jump = list(/obj/item/clothing/under/gimmick/vampire)
	slot_foot = list(/obj/item/clothing/shoes/swat)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/reagent_containers/syringe)
	slot_poc2 = list(/obj/item/reagent_containers/glass/beaker/large)
	slot_back = list(/obj/item/storage/backpack/satchel)

	New()
		..()
		src.access = get_access("Staff Assistant")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("aura", magical=1)
		M.bioHolder.AddEffect("cloak_of_darkness", magical=1)

/datum/job/special/halloween/werewolf
	name = "Discount Werewolf"
	wages = PAY_UNTRAINED
	limit = 1
	change_name_on_spawn = 1
	slot_head = list(/obj/item/clothing/head/werewolf)
	slot_jump = list(/obj/item/clothing/under/shorts)
	slot_suit = list(/obj/item/clothing/suit/gimmick/werewolf)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_belt = list(/obj/item/device/pda2)

	New()
		..()
		src.access = get_access("Staff Assistant")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("jumpy", magical=1)

/datum/job/special/halloween/mummy
	name = "Discount Mummy"
	wages = PAY_UNTRAINED
	limit = 1
	change_name_on_spawn = 1
	slot_mask = list(/obj/item/clothing/mask/mummy)
	slot_jump = list(/obj/item/clothing/under/gimmick/mummy)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_belt = list(/obj/item/device/pda2)

	New()
		..()
		src.access = get_access("Staff Assistant")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("aura", magical=1)
		M.bioHolder.AddEffect("midas", magical=1)

/datum/job/special/halloween/hotdog
	name = "Hot Dog"
	wages = PAY_UNTRAINED
	limit = 1
	change_name_on_spawn = 1
	slot_jump = list(/obj/item/clothing/under/shorts)
	slot_suit = list(/obj/item/clothing/suit/gimmick/hotdog)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_belt = list(/obj/item/device/pda2)
	slot_back = list(/obj/item/storage/backpack/satchel/randoseru)
	slot_poc1 = list(/obj/item/shaker/ketchup)
	slot_poc2 = list(/obj/item/shaker/mustard)

	New()
		..()
		src.access = get_access("Staff Assistant")
		return

/datum/job/special/halloween/godzilla
	name = "Discount Godzilla"
	wages = PAY_UNTRAINED
	limit = 1
	change_name_on_spawn = 1
	slot_head = list(/obj/item/clothing/head/biglizard)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_jump = list(/obj/item/clothing/under/color/green)
	slot_suit = list(/obj/item/clothing/suit/gimmick/dinosaur)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/toy/figure)
	slot_poc2 = list(/obj/item/toy/figure)

	New()
		..()
		src.access = get_access("Staff Assistant")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("lizard", magical=1)
		M.bioHolder.AddEffect("loud_voice", magical=1)

/datum/job/special/halloween/macho
	name = "Discount Macho Man"
	wages = PAY_UNTRAINED
	limit = 1
	change_name_on_spawn = 1
	slot_head = list(/obj/item/clothing/head/helmet/macho)
	slot_eyes = list(/obj/item/clothing/glasses/macho)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_jump = list(/obj/item/clothing/under/gimmick/macho)
	slot_foot = list(/obj/item/clothing/shoes/macho)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/reagent_containers/food/snacks/ingredient/sugar)
	slot_poc2 = list(/obj/item/sticker/ribbon/first_place)

	New()
		..()
		src.access = get_access("Staff Assistant")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("accent_chav", magical=1)

/datum/job/special/halloween/ghost
	name = "Ghost"
	wages = PAY_UNTRAINED
	limit = 1
	change_name_on_spawn = 1
	slot_eyes = list(/obj/item/clothing/glasses/regular/ecto/goggles)
	slot_suit = list(/obj/item/clothing/suit/bedsheet)
	slot_ears = list(/obj/item/device/radio/headset)

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("chameleon", magical=1)

/datum/job/special/halloween/ghost_buster
	name = "Ghost Buster"
	wages = PAY_UNTRAINED
	limit = 1
	change_name_on_spawn = 1
	slot_ears = list(/obj/item/device/radio/headset/ghost_buster)
	slot_eyes = list(/obj/item/clothing/glasses/regular/ecto/goggles)
	slot_jump = list(/obj/item/clothing/under/shirt_pants)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_back = list(/obj/item/storage/backpack/satchel)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/magnifying_glass)
	slot_poc2 = list(/obj/item/shaker/salt)
	items_in_backpack = list(/obj/item/device/camera_viewer/security, /obj/item/device/audio_log, /obj/item/gun/energy/ghost)
	alt_names = list("Paranormal Activities Investigator", "Spooks Specialist")
	change_name_on_spawn = 1

	New()
		..()
		src.access = get_access("Staff Assistant")
		return

/datum/job/special/halloween/angel
	name = "Angel"
	wages = PAY_UNTRAINED
	limit = 1
	change_name_on_spawn = 1
	slot_head = list(/obj/item/clothing/head/laurels/gold)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_jump = list(/obj/item/clothing/under/gimmick/birdman)
	slot_foot = list(/obj/item/clothing/shoes/sandal)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/coin)
	slot_poc2 = list(/obj/item/plant/herb/cannabis/white/spawnable)

	New()
		..()
		src.access = get_access("Chaplain")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("shiny", magical=1)
		M.bioHolder.AddEffect("healing_touch", magical=1)

/datum/job/special/halloween/vendor
	name = "Costume Vendor"
	wages = PAY_TRADESMAN
	limit = 1
	change_name_on_spawn = 1
	slot_jump = list(/obj/item/clothing/under/gimmick/trashsinglet)
	slot_foot = list(/obj/item/clothing/shoes/sandal)
	slot_belt = list(/obj/item/device/pda2)
	slot_back = list(/obj/item/storage/backpack/satchel/anello)
	items_in_backpack = list(/obj/item/storage/box/costume/abomination,
	/obj/item/storage/box/costume/werewolf/odd,
	/obj/item/storage/box/costume/monkey,
	/obj/item/storage/box/costume/eighties,
	/obj/item/clothing/head/zombie)

/datum/job/special/halloween/devil
	name = "Devil"
	wages = PAY_UNTRAINED
	limit = 0
	change_name_on_spawn = 1
	slot_head = list(/obj/item/clothing/head/devil)
	slot_mask = list(/obj/item/clothing/mask/moustache/safe)
	slot_ears = list(/obj/item/device/radio/headset)
	slot_jump = list(/obj/item/clothing/under/misc/lawyer/red/demonic)
	slot_foot = list(/obj/item/clothing/shoes/sandal)
	slot_belt = list(/obj/item/device/pda2)
	slot_poc1 = list(/obj/item/pen/fancy/satan)
	slot_poc2 = list(/obj/item/contract/juggle)

	New()
		..()
		src.access = get_access("Chaplain")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.bioHolder.AddEffect("hell_fire", magical=1)

/datum/job/special/halloween/superhero
	name = "Discount Vigilante Superhero"
	wages = PAY_UNTRAINED
	limit = 1
	change_name_on_spawn = 1
	allow_traitors = 0
	allow_spy_theft = 0
	cant_spawn_as_rev = 1
	receives_miranda = 1
	slot_ears = list(/obj/item/device/radio/headset/security)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses/sechud/superhero)
	slot_glov = list(/obj/item/clothing/gloves/latex/blue)
	slot_jump = list(/obj/item/clothing/under/gimmick/superhero)
	slot_foot = list(/obj/item/clothing/shoes/tourist)
	slot_belt = list(/obj/item/storage/belt/utility/superhero)
	slot_back = list()
	slot_poc2 = list(/obj/item/device/pda2)

	New()
		..()
		src.access = get_access("Staff Assistant")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_security")
		if(prob(60))
			var/aggressive = pick("eyebeams","cryokinesis")
			var/defensive = pick("fire_resist","cold_resist","rad_resist","breathless") // no thermal resist, gotta have some sort of comic book weakness
			var/datum/bioEffect/power/be = M.bioHolder.AddEffect(aggressive, do_stability=0)
			if(aggressive == "eyebeams")
				var/datum/bioEffect/power/eyebeams/eb = be
				eb.stun_mode = 1
				eb.altered = 1
			else
				be.power = 1
				be.altered = 1
			be = M.bioHolder.AddEffect(defensive, do_stability=0)
		else
			var/datum/bioEffect/power/shoot_limb/sl = M.bioHolder.AddEffect("shoot_limb", do_stability=0)
			sl.safety = 1
			sl.altered = 1
			sl.cooldown = 300
			sl.stun_mode = 1
			var/datum/bioEffect/regenerator/r = M.bioHolder.AddEffect("regenerator", do_stability=0)
			r.regrow_prob = 10
		var/datum/bioEffect/power/be = M.bioHolder.AddEffect("adrenaline", do_stability=0)
		be.safety = 1
		be.altered = 1
		M?.mind?.miranda = "Evildoer! You have been apprehended by a hero of space justice!"

/datum/job/special/halloween/pickle
	name = "Pickle"
	wages = PAY_DUMBCLOWN
	limit = 1
	change_name_on_spawn = 1
	slot_ears = list(/obj/item/device/radio/headset)
	slot_suit = list(/obj/item/clothing/suit/gimmick/pickle)
	slot_jump = list(/obj/item/clothing/under/color/green)
	slot_belt = list(/obj/item/device/pda2)
	slot_foot = list(/obj/item/clothing/shoes/black)

	New()
		..()
		src.access = get_access("Staff Assistant")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		var/obj/item/trinket = M.trinket?.deref()
		trinket?.setMaterial(getMaterial("pickle"))
		for (var/i in 1 to 3)
			var/type = pick(trinket_safelist)
			var/obj/item/pickle = new type(M.loc)
			pickle.setMaterial(getMaterial("pickle"))
			M.equip_if_possible(pickle, SLOT_IN_BACKPACK)
		M.bioHolder.RemoveEffect("midas") //just in case mildly mutated has given us midas I guess?
		M.bioHolder.AddEffect("pickle", magical=TRUE)
		M.blood_id = "juice_pickle"

ABSTRACT_TYPE(/datum/job/special/halloween/critter)
/datum/job/special/halloween/critter
	wages = PAY_DUMBCLOWN
	mentor_only = TRUE
	allow_traitors = 0
	slot_ears = list()
	slot_card = null
	slot_back = list()

	special_setup(var/mob/living/carbon/human/M)
		if (!M)
			return

		..()
		// Deactivate any gene that was activated by Mildly mutated trait
		M.bioHolder.DeactivateAllPoolEffects()

/datum/job/special/halloween/critter/plush
	name = "Plush Toy"
	mentor_only = FALSE
	limit = 2

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.critterize(/mob/living/critter/small_animal/plush/cryptid)

/datum/job/special/halloween/critter/remy
	name = "Remy"
	limit = 1

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		var/mob/living/critter/C = M.critterize(/mob/living/critter/small_animal/mouse/remy)
		C.flags = null

/datum/job/special/halloween/critter/bumblespider
	name = "Bumblespider"
	limit = 1

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		var/mob/living/critter/C = M.critterize(/mob/living/critter/spider/nice)
		C.flags = null

/datum/job/special/halloween/critter/crow
	name = "Crow"
	limit = 1

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		var/mob/living/critter/C = M.critterize(/mob/living/critter/small_animal/bird/crow)
		C.flags = null

// end halloween jobs
#endif

/*
/datum/job/special/turkey
	name = "Turkey"
	linkcolor = "#FF7300"
	wages = PAY_DUMBCLOWN
	requires_whitelist = 1
	limit = 1
	allow_traitors = 0
	slot_ears = list()
	slot_card = null
	slot_back = list()

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		var/type = pick(/mob/living/critter/small_animal/bird/turkey/gobbler, /mob/living/critter/small_animal/bird/turkey/hen)
		M.critterize(type)
*/

/datum/job/special/syndicate_weak
	linkcolor = "#880000"
	name = "Junior Syndicate Operative"
	limit = 0
	wages = 0
	slot_back = list(/obj/item/storage/backpack/syndie)
	slot_belt = list(/obj/item/gun/kinetic/pistol)
	slot_jump = list(/obj/item/clothing/under/misc/syndicate)
	slot_suit = list()
	slot_head = list()
	slot_foot = list(/obj/item/clothing/shoes/swat/noslip)
	slot_glov = list(/obj/item/clothing/gloves/swat)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses)
	slot_ears = list()
	slot_mask = list(/obj/item/clothing/mask/gas/swat/syndicate)
	slot_card = null		///obj/item/card/id
	slot_poc1 = list(/obj/item/tank/emergency_oxygen/extended)
	slot_poc2 = list(/obj/item/storage/pouch/bullet_9mm)
	slot_lhan = list()
	slot_rhan = list()
	items_in_backpack = list(
		/obj/item/clothing/head/helmet/space/syndicate,
		/obj/item/clothing/suit/space/syndicate)

	faction = FACTION_SYNDICATE
	radio_announcement = FALSE
	add_to_manifest = FALSE

	special_setup(var/mob/living/carbon/human/M)
		..()
		M.mind?.add_generic_antagonist(ROLE_SYNDICATE_AGENT, "Junior Syndicate Operative", source = ANTAGONIST_SOURCE_ADMIN)

/datum/job/special/syndicate_weak/no_ammo
	name = "Poorly Equipped Junior Syndicate Operative"
	slot_poc2 = list()

	faction = FACTION_SYNDICATE

// hidden jobs for nt-so vs syndicate spec-ops

/datum/job/special/syndicate_specialist
	linkcolor = "#880000"
	name = "Syndicate Special Operative"
	limit = 0
	wages = 0
	allow_traitors = 0
	allow_spy_theft = 0
	cant_spawn_as_rev = 1
	receives_implant = /obj/item/implant/revenge/microbomb
	slot_back = list(/obj/item/storage/backpack/syndie)
	slot_belt = list(/obj/item/storage/belt/gun/pistol)
	slot_jump = list(/obj/item/clothing/under/misc/syndicate)
	slot_suit = list(/obj/item/clothing/suit/space/syndicate/specialist)
	slot_head = list(/obj/item/clothing/head/helmet/space/syndicate/specialist)
	slot_foot = list(/obj/item/clothing/shoes/swat/noslip)
	slot_glov = list(/obj/item/clothing/gloves/swat)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses)
	slot_ears = list(/obj/item/device/radio/headset/syndicate) //needs their own secret channel
	slot_mask = list(/obj/item/clothing/mask/gas/swat/syndicate)
	slot_card = /obj/item/card/id
	slot_poc1 = list(/obj/item/tank/emergency_oxygen/extended)
	slot_poc2 = list(/obj/item/storage/pouch/assault_rifle)
	slot_lhan = list()
	slot_rhan = list(/obj/item/tank/jetpack/syndicate)
	items_in_backpack = list(/obj/item/gun/kinetic/assault_rifle,
							/obj/item/old_grenade/stinger/frag,
							/obj/item/breaching_charge,
							/obj/item/remote/syndicate_teleporter)

	faction = FACTION_SYNDICATE
	radio_announcement = FALSE
	add_to_manifest = FALSE
	special_spawn_location = LANDMARK_SYNDICATE

	New()
		..()
		src.access = syndicate_spec_ops_access()

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.mind?.add_generic_antagonist(ROLE_SYNDICATE_AGENT, "Syndicate Special Operative", source = ANTAGONIST_SOURCE_ADMIN)
		M.show_text("<b>The assault has begun! Head over to the station and kill any and all Nanotrasen personnel you encounter!</b>", "red")

/datum/job/special/pirate
	linkcolor = "#880000"
	name = "Space Pirate"
	limit = 0
	wages = 0
	add_to_manifest = FALSE
	radio_announcement = FALSE
	allow_traitors = FALSE
	allow_spy_theft = FALSE
	cant_spawn_as_rev = TRUE
	slot_card = /obj/item/card/id
	slot_belt = list()
	slot_back = list()
	slot_jump = list()
	slot_foot = list()
	slot_head = list()
	slot_eyes = list()
	slot_ears = list()
	slot_poc1 = list()
	slot_poc2 = list()
	var/rank = ROLE_PIRATE

	New()
		..()
		src.access = list(access_maint_tunnels, access_pirate )
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return

		for (var/datum/antagonist/antag in M.mind.antagonists)
			if (antag.id == ROLE_PIRATE || antag.id == ROLE_PIRATE_FIRST_MATE || antag.id == ROLE_PIRATE_CAPTAIN)
				antag.give_equipment()
				return
		M.mind.add_antagonist(rank, source = ANTAGONIST_SOURCE_ADMIN)


	first_mate
		name = "Space Pirate First Mate"
		rank = ROLE_PIRATE_FIRST_MATE

	captain
		name = "Space Pirate Captain"
		rank = ROLE_PIRATE_CAPTAIN

/datum/job/special/juicer_specialist
	linkcolor = "#cc8899"
	name = "Juicer Security"
	limit = 0
	wages = 0
	allow_traitors = 0
	allow_spy_theft = 0
	cant_spawn_as_rev = 1
	add_to_manifest = FALSE

	slot_back = list(/obj/item/gun/energy/blaster_cannon)
	slot_belt = list(/obj/item/storage/fanny)
	//more

/datum/job/special/ntso_specialist
	linkcolor = "#3348ff"
	name = "Nanotrasen Special Operative"
	limit = 0
	wages = PAY_IMPORTANT
	allow_traitors = 0
	allow_spy_theft = 0
	can_join_gangs = FALSE
	cant_spawn_as_rev = 1
	receives_badge = 1
	receives_miranda = 1
	receives_implant = /obj/item/implant/health
	slot_back = list(/obj/item/storage/backpack/NT)
	slot_belt = list(/obj/item/storage/belt/security/ntso)
	slot_jump = list(/obj/item/clothing/under/misc/turds)
	slot_suit = list(/obj/item/clothing/suit/space/ntso)
	slot_head = list(/obj/item/clothing/head/helmet/space/ntso)
	slot_foot = list(/obj/item/clothing/shoes/swat)
	slot_glov = list(/obj/item/clothing/gloves/swat/NT)
	slot_eyes = list(/obj/item/clothing/glasses/nightvision/sechud/flashblocking)
	slot_ears = list(/obj/item/device/radio/headset/command/nt) //needs their own secret channel
	slot_mask = list(/obj/item/clothing/mask/gas/NTSO)
	slot_card = /obj/item/card/id/nt_specialist
	slot_poc1 = list(/obj/item/device/pda2/heads)
	slot_poc2 = list(/obj/item/storage/ntsc_pouch/ntso)
	items_in_backpack = list(/obj/item/storage/firstaid/regular,
							/obj/item/clothing/head/NTberet,
							/obj/item/currency/spacecash/fivehundred)

	faction = FACTION_NANOTRASEN

	New()
		..()
		src.access = get_all_accesses() + access_centcom
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_security")
		// M.show_text("<b>Hostile assault force incoming! Defend the crew from the attacking Syndicate Special Operatives!</b>", "blue")


/datum/job/special/nt_engineer
	linkcolor = "#3348ff"
	name = "Nanotrasen Emergency Repair Technician"
	limit = 0
	wages = PAY_IMPORTANT
	allow_traitors = 0
	allow_spy_theft = 0
	cant_spawn_as_rev = 1
	slot_back = list(/obj/item/storage/backpack/NT)
	slot_belt = list(/obj/item/storage/belt/utility/nt_engineer)
	slot_jump = list(/obj/item/clothing/under/rank/engineer)
	slot_suit = list(/obj/item/clothing/suit/space/industrial/nt_specialist)
	slot_head = list(/obj/item/clothing/head/helmet/space/ntso)
	slot_foot = list(/obj/item/clothing/shoes/magnetic)
	slot_glov = list(/obj/item/clothing/gloves/yellow)
	slot_eyes = list(/obj/item/clothing/glasses/toggleable/meson)
	slot_ears = list(/obj/item/device/radio/headset/command/nt) //needs their own secret channel
	slot_mask = list(/obj/item/clothing/mask/gas/NTSO)
	slot_card = /obj/item/card/id/nt_specialist
	slot_poc1 = list(/obj/item/tank/emergency_oxygen/extended)
	items_in_backpack = list(/obj/item/storage/firstaid/regular,
							/obj/item/device/flash,
							/obj/item/sheet/steel/fullstack,
							/obj/item/sheet/glass/reinforced/fullstack)

	faction = FACTION_NANOTRASEN

	New()
		..()
		src.access = get_all_accesses() + access_centcom

	special_setup(var/mob/living/carbon/human/M)
		..()
		M?.traitHolder.addTrait("training_engineer")
		SPAWN(1)
			var/obj/item/rcd/rcd = locate() in M.belt.storage.stored_items
			rcd.matter = 100
			rcd.max_matter = 100
			rcd.tooltip_rebuild = TRUE
			rcd.UpdateIcon()

/datum/job/special/nt_medical
	linkcolor = "#3348ff"
	name = "Nanotrasen Emergency Medic"
	limit = 0
	wages = PAY_IMPORTANT
	allow_traitors = 0
	allow_spy_theft = 0
	cant_spawn_as_rev = 1
	slot_back = list(/obj/item/storage/backpack/NT)
	slot_belt = list(/obj/item/storage/belt/medical/prepared)
	slot_jump = list(/obj/item/clothing/under/rank/medical)
	slot_suit = list(/obj/item/clothing/suit/hazard/paramedic/armored)
	slot_head = list(/obj/item/clothing/head/helmet/space/ntso)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_glov = list(/obj/item/clothing/gloves/latex)
	slot_eyes = list(/obj/item/clothing/glasses/healthgoggles/upgraded)
	slot_ears = list(/obj/item/device/radio/headset/command/nt) //needs their own secret channel
	slot_mask = list(/obj/item/clothing/mask/gas/NTSO)
	slot_card = /obj/item/card/id/nt_specialist
	slot_poc1 = list(/obj/item/tank/emergency_oxygen/extended)
	items_in_backpack = list(/obj/item/storage/firstaid/regular,
							/obj/item/device/flash,
							/obj/item/reagent_containers/glass/bottle/omnizine,
							/obj/item/reagent_containers/glass/bottle/ether)

	faction = FACTION_NANOTRASEN

	New()
		..()
		src.access = get_all_accesses() + access_centcom

	special_setup(var/mob/living/carbon/human/M)
		..()
		M?.traitHolder.addTrait("training_medical")

// Use this one for late respawns to deal with existing antags. they are weaker cause they dont get a laser rifle or frags
/datum/job/special/nt_security
	linkcolor = "#3348ff"
	name = "Nanotrasen Security Consultant"
	limit = 1 // backup during HELL WEEK. players will probably like it
	wages = PAY_TRADESMAN
	requires_whitelist = 1
	requires_supervisor_job = "Head of Security"
	allow_traitors = 0
	allow_spy_theft = 0
	can_join_gangs = FALSE
	cant_spawn_as_rev = 1
	receives_badge = 1
	receives_miranda = 1
	receives_implant = /obj/item/implant/health/security/anti_mindhack
	slot_back = list(/obj/item/storage/backpack/NT)
	slot_belt = list(/obj/item/storage/belt/security/ntsc) //special secbelt subtype that spawns with the NTSO gear inside
	slot_jump = list(/obj/item/clothing/under/misc/turds)
	slot_head = list(/obj/item/clothing/head/NTberet)
	slot_foot = list(/obj/item/clothing/shoes/swat)
	slot_glov = list(/obj/item/clothing/gloves/swat/NT)
	slot_eyes = list(/obj/item/clothing/glasses/sunglasses/sechud)
	slot_ears = list(/obj/item/device/radio/headset/command/nt/consultant) //needs their own secret channel
	slot_card = /obj/item/card/id/nt_specialist
	slot_poc1 = list(/obj/item/device/pda2/ntso)
	slot_poc2 = list(/obj/item/currency/spacecash/fivehundred)
	items_in_backpack = list(/obj/item/storage/firstaid/regular,
							/obj/item/clothing/head/helmet/space/ntso,
							/obj/item/clothing/suit/space/ntso,
							/obj/item/cloth/handkerchief/nt)
	wiki_link = "https://wiki.ss13.co/Nanotrasen_Security_Consultant"

	faction = FACTION_NANOTRASEN

	New()
		..()
		src.access = get_access("Security Officer") + list(access_heads)
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_security")


/datum/job/special/headminer
	name = "Head of Mining"
	limit = 0
	wages = PAY_IMPORTANT
	linkcolor = "#00CC00"
	cant_spawn_as_rev = 1
	slot_card = /obj/item/card/id/command
	slot_belt = list(/obj/item/device/pda2/mining)
	slot_jump = list(/obj/item/clothing/under/rank/overalls)
	slot_foot = list(/obj/item/clothing/shoes/orange)
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_ears = list(/obj/item/device/radio/headset/command/ce)
	items_in_backpack = list(/obj/item/tank/emergency_oxygen,/obj/item/crowbar)

	New()
		..()
		src.access = get_access("Head of Mining")
		return

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.traitHolder.addTrait("training_miner")

/datum/job/special/machoman
	name = "Macho Man"
	linkcolor = "#9E0E4D"
	limit = 0
	slot_ears = list()
	slot_card = null
	slot_back = list()
	items_in_backpack = list()
	wiki_link = "https://wiki.ss13.co/Admin#Special_antagonists"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.mind?.add_antagonist(ROLE_MACHO_MAN, source = ANTAGONIST_SOURCE_ADMIN)

/datum/job/special/meatcube
	name = "Meatcube"
	linkcolor = "#FF0000"
	limit = 0
	allow_traitors = 0
	slot_ears = list()
	slot_card = null
	slot_back = list()
	items_in_backpack = list()
	add_to_manifest = FALSE
	wiki_link = "https://wiki.ss13.co/Critter#Other"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.cubeize(INFINITY)

/datum/job/special/ghostdrone
	name = "Drone"
	linkcolor = "#999999"
	limit = 0
	wages = 0
	allow_traitors = 0
	slot_ears = list()
	slot_card = null
	slot_back = list()
	items_in_backpack = list()
	wiki_link = "https://wiki.ss13.co/Ghostdrone"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		droneize(M, 0)

/datum/job/daily //Special daily jobs
	var/day = ""
/datum/job/daily/boxer
	day = "Sunday"
	name = "Boxer"
	wages = PAY_UNTRAINED
	limit = 4
	slot_jump = list(/obj/item/clothing/under/shorts)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_glov = list(/obj/item/clothing/gloves/boxing)
	change_name_on_spawn = 1
	wiki_link = "https://wiki.ss13.co/Boxer"

	New()
		..()
		src.access = get_access("Boxer")
		return

/datum/job/daily/dungeoneer
	day = "Monday"
	name = "Dungeoneer"
	limit = 1
	wages = PAY_UNTRAINED
	slot_belt = list(/obj/item/device/pda2)
	slot_mask = list(/obj/item/clothing/mask/skull)
	slot_jump = list(/obj/item/clothing/under/color/brown)
	slot_suit = list(/obj/item/clothing/suit/cultist/nerd)
	slot_glov = list(/obj/item/clothing/gloves/black)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_poc1 = list(/obj/item/pen/omni)
	slot_poc2 = list(/obj/item/paper)
	items_in_backpack = list(/obj/item/storage/box/nerd_kit)
	change_name_on_spawn = 1
	wiki_link = "https://wiki.ss13.co/Jobs#Job_of_the_Day" // no wiki page yet

	New()
		..()
		src.access = get_access("Dungeoneer")
		return

/datum/job/daily/barber
	day = "Tuesday"
	name = "Barber"
	wages = PAY_UNTRAINED
	limit = 1
	slot_jump = list(/obj/item/clothing/under/misc/barber)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_poc1 = list(/obj/item/scissors)
	slot_poc2 = list(/obj/item/razor_blade)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	wiki_link = "https://wiki.ss13.co/Barber"

	New()
		..()
		src.access = get_access("Barber")
		return

/datum/job/daily/mail_courier
	day = "Wednesday"
	name = "Mail Courier"
	alias_names = "Mailman"
	wages = PAY_TRADESMAN
	limit = 2
	slot_jump = list(/obj/item/clothing/under/misc/mail/syndicate)
	slot_head = list(/obj/item/clothing/head/mailcap)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_back = list(/obj/item/storage/backpack/satchel)
	slot_ears = list(/obj/item/device/radio/headset/mail)
	items_in_backpack = list(/obj/item/wrapping_paper, /obj/item/paper_bin, /obj/item/scissors, /obj/item/stamp)
	alt_names = list("Head of Deliverying", "Mail Bringer")
	wiki_link = "https://wiki.ss13.co/Mailman"

	New()
		..()
		src.access = get_access("Mail Courier")
		return

/datum/job/daily/lawyer
	day = "Thursday"
	name = "Lawyer"
	linkcolor = "#FF0000"
	wages = PAY_DOCTORATE
	limit = 4
	receives_badge = 1
	slot_jump = list(/obj/item/clothing/under/misc/lawyer)
	slot_foot = list(/obj/item/clothing/shoes/black)
	slot_lhan = list(/obj/item/storage/briefcase)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	wiki_link = "https://wiki.ss13.co/Lawyer"

	New()
		..()
		src.access = get_access("Lawyer")
		return


/datum/job/daily/tourist
	day = "Friday"
	name = "Tourist"
	limit = 100
	wages = 0
	linkcolor = "#FF99FF"
	slot_back = null
	slot_belt = list(/obj/item/storage/fanny)
	slot_jump = list(/obj/item/clothing/under/misc/tourist)
	slot_poc1 = list(/obj/item/camera_film)
	slot_poc2 = list(/obj/item/currency/spacecash/tourist) // Exact amount is randomized.
	slot_foot = list(/obj/item/clothing/shoes/tourist)
	slot_lhan = list(/obj/item/camera)
	slot_rhan = list(/obj/item/storage/photo_album)
	change_name_on_spawn = 1
	wiki_link = "https://wiki.ss13.co/Tourist"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		if(prob(33))
			var/morph = pick(/datum/mutantrace/lizard,/datum/mutantrace/skeleton,/datum/mutantrace/ithillid,/datum/mutantrace/martian,/datum/mutantrace/amphibian,/datum/mutantrace/blob,/datum/mutantrace/cow)
			M.set_mutantrace(morph)
		var/obj/item/clothing/lanyard/L = new /obj/item/clothing/lanyard(M.loc)
		M.equip_if_possible(L, SLOT_WEAR_ID, FALSE)
		var/obj/item/card/id = locate() in M
		if (id)
			L.storage.add_contents(id, M, FALSE)

/datum/job/daily/musician
	day = "Saturday"
	name = "Musician"
	limit = 3
	wages = PAY_UNTRAINED
	slot_jump = list(/obj/item/clothing/under/suit/pinstripe)
	slot_head = list(/obj/item/clothing/head/flatcap)
	slot_foot = list(/obj/item/clothing/shoes/brown)
	slot_ears = list(/obj/item/device/radio/headset/civilian)
	items_in_backpack = list(/obj/item/instrument/saxophone,/obj/item/instrument/guitar,/obj/item/instrument/bagpipe,/obj/item/instrument/fiddle)
	change_name_on_spawn = 1
	wiki_link = "https://wiki.ss13.co/Musician"

/datum/job/battler
	name = "Battler"
	limit = -1
	wiki_link = "https://wiki.ss13.co/Battler"

/datum/job/slasher
	name = "The Slasher"
	linkcolor = "#02020d"
	limit = 0
	slot_ears = list()
	slot_card = null
	slot_back = list()
	items_in_backpack = list()
	wiki_link = "https://wiki.ss13.co/The_Slasher"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return
		M.mind?.add_antagonist(ROLE_SLASHER, source = ANTAGONIST_SOURCE_ADMIN)

ABSTRACT_TYPE(/datum/job/special/pod_wars)
/datum/job/special/pod_wars
	name = "Pod_Wars"
#ifdef MAP_OVERRIDE_POD_WARS
	limit = -1
#else
	limit = 0
#endif
	allow_traitors = 0
	cant_spawn_as_rev = 1
	var/team = 0 //1 = NT, 2 = SY
	var/overlay_icon
	wiki_link = "https://wiki.ss13.co/Game_Modes#Pod_Wars"

	special_setup(var/mob/living/carbon/human/M)
		..()
		if (!M)
			return

		if (!M.abilityHolder)
			M.abilityHolder = new /datum/abilityHolder/pod_pilot(src)
			M.abilityHolder.owner = src
		else if (istype(M.abilityHolder, /datum/abilityHolder/composite))
			var/datum/abilityHolder/composite/AH = M.abilityHolder
			AH.addHolder(/datum/abilityHolder/pod_pilot)

		//stuff for headsets
		if (istype(ticker.mode, /datum/game_mode/pod_wars))
			var/datum/game_mode/pod_wars/mode = ticker.mode
			mode.setup_team_overlay(M.mind, overlay_icon)
			if (team == 1)
				M.mind.special_role = mode.team_NT?.name
				setup_headset(M.ears, mode.team_NT?.comms_frequency)
			else if (team == 2)
				M.mind.special_role = mode.team_SY?.name
				setup_headset(M.ears, mode.team_SY?.comms_frequency)

	proc/setup_headset(var/obj/item/device/radio/headset/headset, var/freq)
		if (istype(headset))
			headset.set_secure_frequency("g",freq)
			headset.secure_classes["g"] = RADIOCL_SYNDICATE
			headset.cant_self_remove = 0
			headset.cant_other_remove = 0

	nanotrasen
		name = "NanoTrasen Pod Pilot"
		linkcolor = "#3348ff"
		no_jobban_from_this_job = 1
		low_priority_job = 1
		cant_allocate_unwanted = 1
		access = list(access_heads, access_medical, access_medical_lockers)
		team = 1
		overlay_icon = "nanotrasen"

		faction = FACTION_NANOTRASEN

		receives_implant = /obj/item/implant/pod_wars/nanotrasen
		slot_back = list(/obj/item/storage/backpack/NT)
		slot_belt = list(/obj/item/gun/energy/blaster_pod_wars/nanotrasen)
		slot_jump = list(/obj/item/clothing/under/misc/turds)
		slot_head = list(/obj/item/clothing/head/helmet/space/nanotrasen/pilot)
		slot_suit = list(/obj/item/clothing/suit/space/nanotrasen/pilot)
		slot_foot = list(/obj/item/clothing/shoes/swat)
		slot_card = /obj/item/card/id/pod_wars/nanotrasen
		slot_ears = list(/obj/item/device/radio/headset/pod_wars/nanotrasen)
		slot_mask = list(/obj/item/clothing/mask/breath)
		slot_glov = list(/obj/item/clothing/gloves/swat/NT)
		slot_poc1 = list(/obj/item/tank/emergency_oxygen/extended)
		slot_poc2 = list(/obj/item/device/pda2/pod_wars/nanotrasen)
		items_in_backpack = list(/obj/item/survival_machete, /obj/item/currency/spacecash/hundred)

		commander
			name = "NanoTrasen Commander"
#ifdef MAP_OVERRIDE_POD_WARS
			limit = 1
#else
			limit = 0
#endif
			no_jobban_from_this_job = 0
			high_priority_job = 1
			cant_allocate_unwanted = 1
			overlay_icon = "nanocomm"
			access = list(access_heads, access_captain, access_medical, access_medical_lockers, access_engineering_power)

			slot_head = list(/obj/item/clothing/head/NTberet/commander)
			slot_suit = list(/obj/item/clothing/suit/space/nanotrasen/pilot/commander)
			slot_card = /obj/item/card/id/pod_wars/nanotrasen/commander
			slot_ears = list(/obj/item/device/radio/headset/pod_wars/nanotrasen/commander)

	syndicate
		name = "Syndicate Pod Pilot"
		linkcolor = "#FF0000"
		no_jobban_from_this_job = 1
		low_priority_job = 1
		cant_allocate_unwanted = 1
		access = list(access_syndicate_shuttle, access_medical, access_medical_lockers)
		team = 2
		overlay_icon = "syndicate"
		add_to_manifest = FALSE

		faction = FACTION_SYNDICATE

		receives_implant = /obj/item/implant/pod_wars/syndicate
		slot_back = list(/obj/item/storage/backpack/syndie)
		slot_belt = list(/obj/item/gun/energy/blaster_pod_wars/syndicate)
		slot_jump = list(/obj/item/clothing/under/misc/syndicate)
		slot_head = list(/obj/item/clothing/head/helmet/space/syndicate/specialist)
		slot_suit = list(/obj/item/clothing/suit/space/syndicate)
		slot_foot = list(/obj/item/clothing/shoes/swat)
		slot_card = /obj/item/card/id/pod_wars/syndicate
		slot_ears = list(/obj/item/device/radio/headset/pod_wars/syndicate)
		slot_mask = list(/obj/item/clothing/mask/breath)
		slot_glov = list(/obj/item/clothing/gloves/swat)
		slot_poc1 = list(/obj/item/tank/emergency_oxygen/extended)
		slot_poc2 = list(/obj/item/device/pda2/pod_wars/syndicate)
		items_in_backpack = list(/obj/item/survival_machete/syndicate, /obj/item/currency/spacecash/hundred)

		commander
			name = "Syndicate Commander"
#ifdef MAP_OVERRIDE_POD_WARS
			limit = 1
#else
			limit = 0
#endif
			no_jobban_from_this_job = 0
			high_priority_job = 1
			cant_allocate_unwanted = 1
			overlay_icon = "syndcomm"
			access = list(access_syndicate_shuttle, access_syndicate_commander, access_medical, access_medical_lockers, access_engineering_power)

			slot_head = list(/obj/item/clothing/head/helmet/space/syndicate/commissar_cap)
			slot_suit = list(/obj/item/clothing/suit/space/syndicate/commissar_greatcoat)
			slot_card = /obj/item/card/id/pod_wars/syndicate/commander
			slot_ears = list(/obj/item/device/radio/headset/pod_wars/syndicate/commander)

/datum/job/football
	name = "Football Player"
	limit = -1
	wiki_link = "https://wiki.ss13.co/Game_Modes#Football"

/*---------------------------------------------------------------*/

/datum/job/created
	name = "Special Job"

