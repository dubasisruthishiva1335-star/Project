import { Module } from '@nestjs/common';
import { UploadsController } from './uploads.controller';
import { NotesAdminController } from './notes.admin.controller';
import { JobListingsAdminController } from './job-listings.admin.controller';
import { ResultsAdminController } from './results.admin.controller';
import { AptitudeAdminController } from './aptitude.admin.controller';
import { AnalyticsAdminController } from './analytics.admin.controller';

@Module({
  controllers: [
    UploadsController,
    NotesAdminController,
    JobListingsAdminController,
    ResultsAdminController,
    AptitudeAdminController,
    AnalyticsAdminController,
  ],
})
export class AdminModule {}
