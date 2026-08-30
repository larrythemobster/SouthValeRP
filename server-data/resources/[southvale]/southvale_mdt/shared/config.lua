SouthValeMDT = {}

SouthValeMDT.LeoJobs = { police = true, bcso = true, sasp = true }
SouthValeMDT.SupervisorGrade = 3
SouthValeMDT.WarrantGrade = 2
SouthValeMDT.MaxSentenceMinutes = 240
SouthValeMDT.MaxFine = 250000
SouthValeMDT.Charges = {
    { code = 'TS-01', name = 'Reckless Driving', category = 'Traffic', description = 'Operating a vehicle with willful disregard for public safety.', fine = 750, jail = 0, severity = 'Misdemeanor' },
    { code = 'TS-02', name = 'Evading Police', category = 'Traffic', description = 'Knowingly fleeing a lawful traffic stop or detention.', fine = 1500, jail = 10, severity = 'Misdemeanor' },
    { code = 'CR-01', name = 'Assault', category = 'Violent Crime', description = 'Unlawful physical attack against another person.', fine = 2000, jail = 15, severity = 'Misdemeanor' },
    { code = 'CR-02', name = 'Aggravated Assault', category = 'Violent Crime', description = 'Assault involving a weapon or serious bodily injury.', fine = 5000, jail = 35, severity = 'Felony' },
    { code = 'CR-03', name = 'Robbery', category = 'Property Crime', description = 'Taking property by force, intimidation, or threat.', fine = 4000, jail = 30, severity = 'Felony' },
    { code = 'CR-04', name = 'Burglary', category = 'Property Crime', description = 'Unlawful entry with intent to commit an offense.', fine = 3000, jail = 25, severity = 'Felony' },
    { code = 'CR-05', name = 'Possession of Controlled Substance', category = 'Controlled Substances', description = 'Unlawful possession of a controlled substance.', fine = 2500, jail = 20, severity = 'Felony' },
    { code = 'CR-06', name = 'Possession of an Illegal Firearm', category = 'Weapons', description = 'Possession of a firearm prohibited by law.', fine = 5000, jail = 30, severity = 'Felony' },
    { code = 'CR-07', name = 'Murder', category = 'Violent Crime', description = 'Unlawful killing of another person with malice aforethought.', fine = 25000, jail = 120, severity = 'Felony' },
}
