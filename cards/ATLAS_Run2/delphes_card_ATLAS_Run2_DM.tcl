#######################################
# Order of execution of various modules
#######################################

set ExecutionPath {
  ParticlePropagator

  ChargedHadronTrackingEfficiency
  ElectronTrackingEfficiency
  MuonTrackingEfficiency

  ChargedHadronMomentumSmearing
  ElectronMomentumSmearing
  MuonMomentumSmearing

  TrackMerger
  Calorimeter
  EFlowMerger
  
  MissingET

  FastJetFinder
  FatJetFinder
  
  JetEnergyScale

  JetFlavorAssociation
  BTagging
  TauTagging

  TagSkimmer

  TreeWriter
}

#################################
# Propagate particles in cylinder
#################################

module ParticlePropagator ParticlePropagator {
  set InputArray Delphes/stableParticles

  set OutputArray stableParticles
  set ChargedHadronOutputArray chargedHadrons
  set ElectronOutputArray electrons
  set MuonOutputArray muons

  # radius of the magnetic field coverage, in m
  set Radius 1.15
  # half-length of the magnetic field coverage, in m
  set HalfLength 3.51

  # magnetic field
  set Bz 2.0
}

####################################
# Charged hadron tracking efficiency
####################################

module Efficiency ChargedHadronTrackingEfficiency {
  set InputArray ParticlePropagator/chargedHadrons
  set OutputArray chargedHadrons

  # Source file from detector card
  source tracking/chargedHadrons.tcl
}

##############################
# Electron tracking efficiency
##############################

module Efficiency ElectronTrackingEfficiency {
  set InputArray ParticlePropagator/electrons
  set OutputArray electrons

  # Source file from detector card
  source tracking/elecMuon_loose.tcl
}

##########################
# Muon tracking efficiency
##########################

module Efficiency MuonTrackingEfficiency {
  set InputArray ParticlePropagator/muons
  set OutputArray muons

  # Source file from detector card
  source tracking/elecMuon_loose.tcl
}

########################################
# Momentum resolution for charged tracks
########################################

module MomentumSmearing ChargedHadronMomentumSmearing {
  set InputArray ChargedHadronTrackingEfficiency/chargedHadrons
  set OutputArray chargedHadrons

  # Resolution formula from detector card
  set ResolutionFormula {                   (abs(eta) <= 0.5) * (pt > 0.1) * sqrt(0.06^2 + pt^2*1.3e-3^2) +
                          (abs(eta) > 0.5 && abs(eta) <= 1.5) * (pt > 0.1) * sqrt(0.10^2 + pt^2*1.7e-3^2) +
                          (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 0.1) * sqrt(0.25^2 + pt^2*3.1e-3^2)}
}

###################################
# Momentum resolution for electrons
###################################

module MomentumSmearing ElectronMomentumSmearing {
  set InputArray ElectronTrackingEfficiency/electrons
  set OutputArray electrons

  # Source file from detector card
  source resolution/electron_momentum.tcl
}

###############################
# Momentum resolution for muons 
###############################

module MomentumSmearing MuonMomentumSmearing {
  set InputArray MuonTrackingEfficiency/muons
  set OutputArray muons

  # Source file from detector card
  source resolution/muons/cb_muons_pt_res.tcl
}

##############
# Track merger
##############

module Merger TrackMerger {
  add InputArray ChargedHadronMomentumSmearing/chargedHadrons
  add InputArray ElectronMomentumSmearing/electrons
  # Note: Muons are often treated separately or added here depending on specific flow preferences.
  # The skimmed file had muons commented out, detector card used them in PileUpSubtractor.
  # Keeping standard merging logic:
  add InputArray MuonMomentumSmearing/muons
  set OutputArray tracks
}

#############
# Calorimeter
#############

module Calorimeter Calorimeter {
  set ParticleInputArray ParticlePropagator/stableParticles
  set TrackInputArray TrackMerger/tracks

  set TowerOutputArray towers
  set PhotonOutputArray photons

  set EFlowTrackOutputArray eflowTracks
  set EFlowPhotonOutputArray eflowPhotons
  set EFlowNeutralHadronOutputArray eflowNeutralHadrons

  set ECalEnergyMin 0.5
  set HCalEnergyMin 1.0

  set ECalEnergySignificanceMin 1.0
  set HCalEnergySignificanceMin 1.0

  set SmearTowerCenter true
  
  set pi [expr {acos(-1)}]
  set PhiBins {}
  for {set i -18} {$i <= 18} {incr i} {
    add PhiBins [expr {$i * $pi/18.0}]
  }
  foreach eta {-3.2 -2.5 -2.4 -2.3 -2.2 -2.1 -2 -1.9 -1.8 -1.7 -1.6 -1.5 -1.4 -1.3 -1.2 -1.1 -1 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2 2.1 2.2 2.3 2.4 2.5 2.6 3.3} {
    add EtaPhiBins $eta $PhiBins
  }
  set PhiBins {}
  for {set i -9} {$i <= 9} {incr i} {
    add PhiBins [expr {$i * $pi/9.0}]
  }
  foreach eta {-4.9 -4.7 -4.5 -4.3 -4.1 -3.9 -3.7 -3.5 -3.3 -3 -2.8 -2.6 2.8 3 3.2 3.5 3.7 3.9 4.1 4.3 4.5 4.7 4.9} {
    add EtaPhiBins $eta $PhiBins
  }

  add EnergyFraction {0} {0.0 1.0}
  add EnergyFraction {11} {1.0 0.0}
  add EnergyFraction {22} {1.0 0.0}
  add EnergyFraction {111} {1.0 0.0}
  add EnergyFraction {12} {0.0 0.0}
  add EnergyFraction {13} {0.0 0.0}
  add EnergyFraction {14} {0.0 0.0}
  add EnergyFraction {16} {0.0 0.0}
  
  # Invisible Particles (MET contributors) from your list
  add EnergyFraction {51} {0.0 0.0}
  add EnergyFraction {53} {0.0 0.0}
  add EnergyFraction {4900101} {0.0 0.0}
  add EnergyFraction {4900111} {0.0 0.0}
  add EnergyFraction {4900113} {0.0 0.0}
  add EnergyFraction {4900991} {0.0 0.0}
  add EnergyFraction {9000005} {0.0 0.0}
  add EnergyFraction {9000006} {0.0 0.0}
  add EnergyFraction {9000007} {0.0 0.0}
  add EnergyFraction {9000008} {0.0 0.0}
  add EnergyFraction {9000009} {0.0 0.0}
  add EnergyFraction {9000010} {0.0 0.0}
  add EnergyFraction {9000011} {0.0 0.0}
  add EnergyFraction {9000012} {0.0 0.0}
  add EnergyFraction {9000013} {0.0 0.0}
  add EnergyFraction {9000014} {0.0 0.0}
  add EnergyFraction {9000015} {0.0 0.0}
  add EnergyFraction {9000016} {0.0 0.0}
  add EnergyFraction {9000017} {0.0 0.0}
  add EnergyFraction {9000018} {0.0 0.0}
  add EnergyFraction {9000019} {0.0 0.0}
  add EnergyFraction {9000020} {0.0 0.0}
  add EnergyFraction {9000021} {0.0 0.0}
  add EnergyFraction {9000022} {0.0 0.0}
  add EnergyFraction {9000023} {0.0 0.0}
  add EnergyFraction {9000024} {0.0 0.0}
  add EnergyFraction {9000025} {0.0 0.0}
  add EnergyFraction {9000026} {0.0 0.0}
  add EnergyFraction {9000027} {0.0 0.0}
  add EnergyFraction {9000028} {0.0 0.0}
  add EnergyFraction {9000111} {0.0 0.0}
  add EnergyFraction {9000211} {0.0 0.0}
  
  # Standard Invisibles often included in SUSY/BSM cards
  add EnergyFraction {1000022} {0.0 0.0}
  add EnergyFraction {1000023} {0.0 0.0}
  add EnergyFraction {1000025} {0.0 0.0}
  add EnergyFraction {1000035} {0.0 0.0}
  add EnergyFraction {1000045} {0.0 0.0}

  add EnergyFraction {310} {0.3 0.7}
  add EnergyFraction {3122} {0.3 0.7}

  # Resolution formulas from detector card
  set ECalResolutionFormula {                   (abs(eta) <= 3.2) * sqrt(energy^2*0.0017^2 + energy*0.101^2) +
                              (abs(eta) > 3.2 && abs(eta) <= 4.9) * sqrt(energy^2*0.0350^2 + energy*0.285^2)}
  set HCalResolutionFormula {                   (abs(eta) <= 1.7) * sqrt(energy^2*0.0302^2 + energy*0.5205^2 + 1.59^2) +
                              (abs(eta) > 1.7 && abs(eta) <= 3.2) * sqrt(energy^2*0.0500^2 + energy*0.706^2) +
                              (abs(eta) > 3.2 && abs(eta) <= 4.9) * sqrt(energy^2*0.09420^2 + energy*1.00^2)}
}

####################
# Energy flow merger
####################

module Merger EFlowMerger {
  add InputArray Calorimeter/eflowTracks
  add InputArray Calorimeter/eflowPhotons
  add InputArray Calorimeter/eflowNeutralHadrons
  set OutputArray eflow
}

###################
# Missing ET merger
###################

module Merger MissingET {
  add InputArray EFlowMerger/eflow
  set MomentumOutputArray momentum
}

#####################
# Jet Finder (Standard)
#####################

module FastJetFinder FastJetFinder {
  set InputArray EFlowMerger/eflow
  set OutputArray jets

  set JetAlgorithm 6
  set ParameterR 0.4
  
  set ConeRadius 0.5
  set SeedThreshold 1.0
  set ConeAreaFraction 1.0
  set AdjacencyCut 2
  set OverlapThreshold 0.75
  set MaxIterations 100
  set MaxPairSize 2
  set Iratch 1
  
  set JetPTMin 20.0
}

#####################
# Fat Jet Finder (Large R)
#####################

module FastJetFinder FatJetFinder {
  set InputArray EFlowMerger/eflow
  set OutputArray jets

  set JetAlgorithm 6
  set ParameterR 1.0

  set ComputeNsubjettiness 1
  set Beta 1.0
  set AxisMode 4

  set ComputeTrimming 1
  set RTrim 0.2
  set PtFracTrim 0.05

  set JetPTMin 250.0
}

##################
# Jet Energy Scale
##################

module EnergyScale JetEnergyScale {
  set InputArray FastJetFinder/jets
  set OutputArray jets

  # Using formula from original skimmed file as it provides specific corrections
  set ScaleFormula { 1.0 + (pt <= 100.)*(-0.01864*log(pt) + 0.10084) + (pt > 100.)*0.015 }
}

########################
# Jet Flavor Association
########################

module JetFlavorAssociation JetFlavorAssociation {
  set PartonInputArray Delphes/partons
  set ParticleInputArray Delphes/allParticles
  set ParticleLHEFInputArray Delphes/allParticlesLHEF
  set JetInputArray JetEnergyScale/jets
  
  set DeltaR 0.5
  set PartonPTMin 1.0
  set PartonEtaMax 2.5
}

###########
# b-tagging
###########

module BTagging BTagging {
  set JetInputArray JetEnergyScale/jets
  set BitNumber 0

  # Standard B-tagging efficiencies adjusted for ~77% WP as requested
  # Using formula logic similar to standard ATLAS cards but tuned for 77%
  
  # b-quarks (77% efficiency)
  add EfficiencyFormula {5} {0.77}
  
  # c-quarks (approx 1/6 mistag rate)
  add EfficiencyFormula {4} {0.16}
  
  # light quarks (approx 1/134 mistag rate)
  add EfficiencyFormula {0} {0.0075}
}

#############
# tau-tagging
#############

module TrackCountingTauTagging TauTagging {
  set ParticleInputArray Delphes/allParticles
  set PartonInputArray Delphes/partons
  set TrackInputArray TrackMerger/tracks
  set JetInputArray JetEnergyScale/jets

  set DeltaR 0.2
  set DeltaRTrack 0.2
  set TrackPTMin 1.0
  set TauPTMin 1.0
  set TauEtaMax 2.5
  
  set BitNumber 0
  
  # Efficiencies from detector card
  add EfficiencyFormula {1} {0.70}
  add EfficiencyFormula {2} {0.60}
  add EfficiencyFormula {-1} {0.02}
  add EfficiencyFormula {-2} {0.01}
}

module TaggingParticlesSkimmer TagSkimmer {
  set ParticleInputArray Delphes/allParticles
  set PartonInputArray Delphes/partons
  
  set OutputArray particles

  set PTMin 1.0
  set EtaMax 5.0
}

##################
# ROOT tree writer
##################

module TreeWriter TreeWriter {
  add Branch TagSkimmer/particles Particle GenParticle
  add Branch Delphes/allParticles GenParticle GenParticle  

  add Branch TrackMerger/tracks Track Track
  add Branch EFlowMerger/eflow Tower Tower

  # Output for both jet collections
  add Branch JetEnergyScale/jets Jet Jet
  add Branch FatJetFinder/jets FatJet Jet
  
  add Branch ElectronMomentumSmearing/electrons Electron Electron
  add Branch Calorimeter/photons Photon Photon
  add Branch MuonMomentumSmearing/muons Muon Muon
  add Branch MissingET/momentum MissingET MissingET
}