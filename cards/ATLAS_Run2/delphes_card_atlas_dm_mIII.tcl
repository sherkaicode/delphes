#######################################
# Order of execution of various modules
#######################################
# Improved updated the parametric fit from the delphes_ATLAS_PileUp Card 
# Presentation, data, and code for the fits of the updates can be seen here: https://zenodo.org/records/17622130

set ExecutionPath {
  ParticlePropagator

  ChargedHadronTrackingEfficiency
  ElectronTrackingEfficiency
  MuonTrackingEfficiency

  ChargedHadronMomentumSmearing
  ElectronMomentumSmearing
  MuonMomentumSmearing

  TrackMerger
  TrackSmearing
  Calorimeter
  ElectronFilter
  NeutralTowerMerger
  EFlowMergerAllTracks
  EFlowMerger
  EFlowFilter
  
  NeutrinoFilter
  GenJetFinder
  GenMissingET
  
  FastJetFinder
  FatJetFinder
  JetEnergyScale

  PhotonEfficiency
  PhotonIsolation

  ElectronEfficiency
  ElectronIsolation

  MuonEfficiency
  MuonIsolation

  MissingET
  
  JetFlavorAssociation

  BTagging
  TauTagging

  UniqueObjectFinder

  ScalarHT

  TreeWriter
}

#################################
# Propagate particles in cylinder (https://cds.cern.ch/record/331063/files/ATLAS-TDR-4-Volume-I.pdf. Chapter 1.2.2) 
#################################

module ParticlePropagator ParticlePropagator {
  set InputArray Delphes/stableParticles

  set OutputArray stableParticles
  set ChargedHadronOutputArray chargedHadrons
  set ElectronOutputArray electrons
  set MuonOutputArray muons

  set Radius 1.15
  set HalfLength 3.45

  set Bz 2.0
}

####################################
# Charged hadron tracking efficiency
####################################

module Efficiency ChargedHadronTrackingEfficiency {
  set InputArray ParticlePropagator/chargedHadrons
  set OutputArray chargedHadrons

  source tracking/chargedHadrons.tcl
}

##############################
# Electron tracking efficiency
##############################

module Efficiency ElectronTrackingEfficiency {
  set InputArray ParticlePropagator/electrons
  set OutputArray electrons

  source tracking/elecMuon_loose.tcl
}

##########################
# Muon tracking efficiency
##########################

module Efficiency MuonTrackingEfficiency {
  set InputArray ParticlePropagator/muons
  set OutputArray muons

  source tracking/elecMuon_loose.tcl
}

########################################
# Momentum resolution for charged tracks
########################################

module MomentumSmearing ChargedHadronMomentumSmearing {
  set InputArray ChargedHadronTrackingEfficiency/chargedHadrons
  set OutputArray chargedHadrons
  set ResolutionFormula {                  (abs(eta) <= 0.5) * (pt > 0.1) * sqrt(0.06^2 + pt^2*1.3e-3^2) +
                         (abs(eta) > 0.5 && abs(eta) <= 1.5) * (pt > 0.1) * sqrt(0.10^2 + pt^2*1.7e-3^2) +
                         (abs(eta) > 1.5 && abs(eta) <= 2.5) * (pt > 0.1) * sqrt(0.25^2 + pt^2*3.1e-3^2)}
}

###################################
# Momentum resolution for electrons
###################################

module MomentumSmearing ElectronMomentumSmearing {
  set InputArray ElectronTrackingEfficiency/electrons
  set OutputArray electrons
  source resolution/electron_momentum.tcl
}

###############################
# Momentum resolution for muons 
###############################

module MomentumSmearing MuonMomentumSmearing {
  set InputArray MuonTrackingEfficiency/muons
  set OutputArray muons
  source resolution/muons/cb_muons_pt_res.tcl
}

##############
# Track merger
##############
  
module Merger TrackMerger {
  add InputArray ChargedHadronMomentumSmearing/chargedHadrons
  add InputArray ElectronMomentumSmearing/electrons
  add InputArray MuonMomentumSmearing/muons
  set OutputArray tracks
}
module TrackSmearing TrackSmearing {
  set InputArray TrackMerger/tracks
  set OutputArray tracks
  set Bz 2.0

  source trackResolutionATLAS.tcl
}

#############
# Calorimeter
#############

module Calorimeter Calorimeter {
  set ParticleInputArray ParticlePropagator/stableParticles
  set TrackInputArray TrackSmearing/tracks
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

  # 10 degrees towers
  set PhiBins {}
  for {set i -18} {$i <= 18} {incr i} {
    add PhiBins [expr {$i * $pi/18.0}]
  }
  foreach eta {-3.2 -2.5 -2.4 -2.3 -2.2 -2.1 -2 -1.9 -1.8 -1.7 -1.6 -1.5 -1.4 -1.3 -1.2 -1.1 -1 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2 2.1 2.2 2.3 2.4 2.5 2.6 3.3} {
    add EtaPhiBins $eta $PhiBins
  }

  # 20 degrees towers
  set PhiBins {}
  for {set i -9} {$i <= 9} {incr i} {
    add PhiBins [expr {$i * $pi/9.0}]
  }
  foreach eta {-4.9 -4.7 -4.5 -4.3 -4.1 -3.9 -3.7 -3.5 -3.3 -3 -2.8 -2.6 2.8 3 3.2 3.5 3.7 3.9 4.1 4.3 4.5 4.7 4.9} {
    add EtaPhiBins $eta $PhiBins
  }

  # default energy fractions {abs(PDG code)} {Fecal Fhcal}
  add EnergyFraction {0} {0.0 1.0}
  # energy fractions for e, gamma and pi0
  add EnergyFraction {11} {1.0 0.0}
  add EnergyFraction {22} {1.0 0.0}
  add EnergyFraction {111} {1.0 0.0}
  # energy fractions for muon, neutrinos and neutralinos
  add EnergyFraction {12} {0.0 0.0}
  add EnergyFraction {13} {0.0 0.0}
  add EnergyFraction {14} {0.0 0.0}
  add EnergyFraction {16} {0.0 0.0}
  add EnergyFraction {1000022} {0.0 0.0}
  add EnergyFraction {1000023} {0.0 0.0}
  add EnergyFraction {1000025} {0.0 0.0}
  add EnergyFraction {1000035} {0.0 0.0}
  add EnergyFraction {1000045} {0.0 0.0}

  # --- BSM HV INVISIBLES ---
  # Visible Diagonals (Included here in case they are set to be stable)
  add EnergyFraction {4900111} {0.0 0.0}
  add EnergyFraction {4900113} {0.0 0.0}

  # Simple Setup Stable Hadrons (Off-Diagonals & Glueballs)
  add EnergyFraction {4900211} {0.0 0.0}
  add EnergyFraction {-4900211} {0.0 0.0}
  add EnergyFraction {4900213} {0.0 0.0}
  add EnergyFraction {-4900213} {0.0 0.0}
  add EnergyFraction {4900991} {0.0 0.0}

  # Hidden Baryons (Deltav)
  add EnergyFraction {4901114} {0.0 0.0}
  add EnergyFraction {-4901114} {0.0 0.0}

  # Hidden Quarks (Stable in U(1) or pre-hadronization)
  add EnergyFraction {4900101} {0.0 0.0}
  add EnergyFraction {4900102} {0.0 0.0}
  add EnergyFraction {4900103} {0.0 0.0}
  add EnergyFraction {4900104} {0.0 0.0}
  add EnergyFraction {4900105} {0.0 0.0}
  add EnergyFraction {4900106} {0.0 0.0}
  add EnergyFraction {4900107} {0.0 0.0}
  add EnergyFraction {4900108} {0.0 0.0}

  # Hidden Gauge Bosons
  add EnergyFraction {4900021} {0.0 0.0} 
  add EnergyFraction {4900022} {0.0 0.0} 

  # Generic Dark Matter (The ones used in your specific Rinv decay)
  add EnergyFraction {51} {0.0 0.0}
  add EnergyFraction {-51} {0.0 0.0}
  add EnergyFraction {53} {0.0 0.0}
  add EnergyFraction {-53} {0.0 0.0}
  add EnergyFraction {52} {0.0 0.0}
  add EnergyFraction {54} {0.0 0.0}

  add EnergyFraction {4900121} {0.0 0.0}
  add EnergyFraction {4900123} {0.0 0.0}
  add EnergyFraction {4900231} {0.0 0.0}
  add EnergyFraction {4900233} {0.0 0.0}
  
  # energy fractions for K0short and Lambda
  add EnergyFraction {310} {0.3 0.7}
  add EnergyFraction {3122} {0.3 0.7}

  # set ECalResolutionFormula {resolution formula as a function of eta and energy}
  # http://arxiv.org/pdf/physics/0608012v1 jinst8_08_s08003
  # http://villaolmo.mib.infn.it/ICATPP9th_2005/Calorimetry/Schram.p.pdf
  # http://www.physics.utoronto.ca/~krieger/procs/ComoProceedings.pdf
  set ECalResolutionFormula {                  (abs(eta) <= 3.2) * sqrt(energy^2*0.0017^2 + energy*0.101^2) +
                             (abs(eta) > 3.2 && abs(eta) <= 4.9) * sqrt(energy^2*0.0350^2 + energy*0.285^2)}

  # set HCalResolutionFormula {resolution formula as a function of eta and energy}
  # http://arxiv.org/pdf/hep-ex/0004009v1
  # http://villaolmo.mib.infn.it/ICATPP9th_2005/Calorimetry/Schram.p.pdf
  set HCalResolutionFormula {                  (abs(eta) <= 1.7) * sqrt(energy^2*0.0302^2 + energy*0.5205^2 + 1.59^2) +
                             (abs(eta) > 1.7 && abs(eta) <= 3.2) * sqrt(energy^2*0.0500^2 + energy*0.706^2) +
                             (abs(eta) > 3.2 && abs(eta) <= 4.9) * sqrt(energy^2*0.09420^2 + energy*1.00^2)}
}

#################
# Electron filter
#################

module PdgCodeFilter ElectronFilter {
  set InputArray Calorimeter/eflowTracks
  set OutputArray electrons
  set Invert true
  add PdgCode {11}
  add PdgCode {-11}
}

####################
# Neutral tower merger
####################

module Merger NeutralTowerMerger {
  add InputArray Calorimeter/eflowPhotons
  add InputArray Calorimeter/eflowNeutralHadrons
  set OutputArray eflowTowers
}

##################################
# Energy flow merger (all tracks)
##################################

module Merger EFlowMergerAllTracks {
  add InputArray TrackSmearing/tracks
  add InputArray Calorimeter/eflowPhotons
  add InputArray Calorimeter/eflowNeutralHadrons
  set OutputArray eflow
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

######################
# EFlowFilter
######################

module PdgCodeFilter EFlowFilter {
  set InputArray EFlowMerger/eflow
  set OutputArray eflow
  
  add PdgCode {11}
  add PdgCode {-11}
  add PdgCode {13}
  add PdgCode {-13}
}

#####################
# Neutrino Filter
#####################

module PdgCodeFilter NeutrinoFilter {

  set InputArray Delphes/stableParticles
  set OutputArray filteredParticles

  set PTMin 0.0

  add PdgCode {12}
  add PdgCode {14}
  add PdgCode {16}
  add PdgCode {-12}
  add PdgCode {-14}
  add PdgCode {-16}

}

#####################
# MC truth jet finder
#####################

module FastJetFinder GenJetFinder {
  set InputArray NeutrinoFilter/filteredParticles

  set OutputArray jets

  # algorithm: 1 CDFJetClu, 2 MidPoint, 3 SIScone, 4 kt, 5 Cambridge/Aachen, 6 antikt
  set JetAlgorithm 6
  set ParameterR 0.4

  set JetPTMin 20.0
}

#########################
# Gen Missing ET merger
########################

module Merger GenMissingET {
  add InputArray NeutrinoFilter/filteredParticles
  set MomentumOutputArray momentum
}


############
# Jet finder
############

module FastJetFinder FastJetFinder {
  set InputArray Calorimeter/towers
  set OutputArray jets
  set JetAlgorithm 6
  set ParameterR 0.4
  set JetPTMin 20.0
}

##################
# Fat Jet finder
##################

module FastJetFinder FatJetFinder {
  set InputArray Calorimeter/towers
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
  
  # Mark III
  # set ScaleFormula { 1.0 + (pt <= 100.)*(-0.01864*log(pt) + 0.10084) + (pt > 100.)*0.015 }  
  # Mark IV
  # set ScaleFormula {  sqrt( (3.0 - 0.2*(abs(eta)))^2 / pt + 1.0 )  }
  # Mark VII
  set ScaleFormula {1.0}
}

###################
# Photon efficiency
###################

module Efficiency PhotonEfficiency {
  set InputArray Calorimeter/eflowPhotons
  set OutputArray photons

  source efficiency/photon.tcl
}

##################
# Photon isolation
##################

module Isolation PhotonIsolation {
  set CandidateInputArray PhotonEfficiency/photons
  set IsolationInputArray EFlowFilter/eflow

  set OutputArray photons
  set DeltaRMax 0.2

  set PTMin 1.0
  set PTRatioMax 0.05
}

#####################
# Electron efficiency
#####################

module Efficiency ElectronEfficiency {
  add InputArray ElectronFilter/electrons
  set OutputArray electrons
  source efficiency/electron_medium.tcl

}

####################
# Electron isolation
####################

module Isolation ElectronIsolation {
  set CandidateInputArray ElectronEfficiency/electrons
  set IsolationInputArray EFlowFilter/eflow

  set OutputArray electrons
  set DeltaRMax 0.2

  set PTMin 1.0
  set PTRatioMax 0.15
}

#################
# Muon efficiency
#################

module Efficiency MuonEfficiency {
  add InputArray MuonMomentumSmearing/muons
  set OutputArray muons
  source efficiency/muon_medium.tcl

}
################
# Muon isolation
################

module Isolation MuonIsolation {
  set CandidateInputArray MuonEfficiency/muons
  set IsolationInputArray EFlowFilter/eflow

  set OutputArray muons

  # https://cds.cern.ch/record/2746302/files/Aad2021_Article_MuonReconstructionAndIdentific.pdf
  set DeltaRMax 0.3
  
  set PTMin 1.0
  # Loose (0.3), Tight (0.15)
  set PTRatioMax 0.3
}

###################
# Missing ET merger
###################

module Merger MissingET {
  add InputArray EFlowMergerAllTracks/eflow
  set MomentumOutputArray momentum
}


##################
# Scalar HT merger
##################

module Merger ScalarHT {
# add InputArray InputArray
  add InputArray UniqueObjectFinder/jets
  add InputArray UniqueObjectFinder/electrons
  add InputArray UniqueObjectFinder/photons
  add InputArray UniqueObjectFinder/muons
  set EnergyOutputArray energy
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

  add EfficiencyFormula {0} {0.00677 + 2.1e-06*pt}
  add EfficiencyFormula {4} {0.186*tanh(0.60700*pt)*(1/(1 + 0.00097*pt))}
  add EfficiencyFormula {5} {2.993*tanh(0.00181*pt)*(30/(1 + 0.18066*pt))}
}

#############
# tau-tagging
#############

module TrackCountingTauTagging TauTagging {
 
  set ParticleInputArray Delphes/allParticles
  set PartonInputArray Delphes/partons
  set TrackInputArray TrackSmearing/tracks
  set JetInputArray JetEnergyScale/jets

  set DeltaR 0.2
  set DeltaRTrack 0.2

  set TrackPTMin 1.0
 
  set TauPTMin 1.0
  set TauEtaMax 2.5

  # instructions: {n-prongs} {eff} 
  
  # 1 - one prong efficiency
  # 2 - two or more efficiency
  # -1 - one prong mistag rate
  # -2 - two or more mistag rate
 
  set BitNumber 0
 
  # taken from ATL-PHYS-PUB-2015-045 (medium working point)
  add EfficiencyFormula {1} {0.70}
  add EfficiencyFormula {2} {0.60}
  add EfficiencyFormula {-1} {0.02}
  add EfficiencyFormula {-2} {0.01}

}

#####################################################
# Find uniquely identified photons/electrons/tau/jets
#####################################################

module UniqueObjectFinder UniqueObjectFinder {
# earlier arrays take precedence over later ones
# add InputArray InputArray OutputArray
  add InputArray PhotonIsolation/photons photons
  add InputArray ElectronIsolation/electrons electrons
  add InputArray MuonIsolation/muons muons
  add InputArray JetEnergyScale/jets jets
}

##################
# ROOT tree writer
##################

module TreeWriter TreeWriter {
  add Branch Delphes/allParticles Particle GenParticle
  add Branch Calorimeter/towers Tower Tower
  add Branch EFlowMerger/eflow ParticleFlowCandidate ParticleFlowCandidate
  add Branch GenJetFinder/jets GenJet Jet
  add Branch GenMissingET/momentum GenMissingET MissingET
  add Branch UniqueObjectFinder/jets Jet Jet
  add Branch UniqueObjectFinder/electrons Electron Electron
  add Branch UniqueObjectFinder/photons Photon Photon
  add Branch UniqueObjectFinder/muons Muon Muon
  add Branch FatJetFinder/jets FatJet Jet
  add Branch FastJetFinder/jets SmallJet Jet
  add Branch MissingET/momentum MissingET MissingET
  add Branch ScalarHT/energy ScalarHT ScalarHT
}
